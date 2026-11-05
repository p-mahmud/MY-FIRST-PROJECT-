import express from 'express';
import path from 'path';
import { createServer as createViteServer } from 'vite';
import { db } from './src/server/db.js';
import { Collection } from './src/types.js';

async function startServer() {
  const app = express();
  const PORT = 3000;

  // Middleware to support large JSON payload (such as profile picture base64 or receipts)
  app.use(express.json({ limit: '50mb' }));
  app.use(express.urlencoded({ limit: '50mb', extended: true }));

  // ==========================================
  // AUTHENTICATION ENDPOINTS
  // ==========================================
  
  app.post('/api/auth/login', (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
       res.status(400).json({ error: 'Username/Email and Password are required.' });
       return;
    }

    // 1. Check Admin Account (Hardcoded requirement: pavel28 / 123456789)
    if (username === 'pavel28' && password === '123456789') {
      db.addLog('pavel28', 'Login', 'Admin logged in successfully');
      res.json({
        user: {
          username: 'pavel28',
          name: 'Pavel Mahmud (Admin)',
          role: 'admin'
        },
        token: 'admin-mock-token-session'
      });
      return;
    }

    // 2. Check User Accounts (Seeded or newly added members)
    // Users can login using their Member ID (e.g. MEM-001) or their email.
    // Default password is '123456789' or their registered phone number.
    const members = db.getMembers();
    const matchedMember = members.find(m => 
      (m.id.toLowerCase() === username.toLowerCase() || m.email.toLowerCase() === username.toLowerCase())
    );

    if (matchedMember) {
      const isPasswordCorrect = password === '123456789' || password === matchedMember.phone;
      if (isPasswordCorrect) {
        if (matchedMember.status !== 'active') {
           res.status(403).json({ error: 'Your account is deactivated. Please contact the administrator.' });
           return;
        }

        db.addLog(matchedMember.name, 'Login', `Member ${matchedMember.name} logged in`);
        res.json({
          user: {
            id: matchedMember.id,
            username: matchedMember.id,
            name: matchedMember.name,
            role: 'user',
            email: matchedMember.email,
            phone: matchedMember.phone,
            address: matchedMember.address,
            avatar: matchedMember.avatar
          },
          token: `member-mock-token-${matchedMember.id}`
        });
        return;
      }
    }

    res.status(401).json({ error: 'Invalid username, email, or password.' });
  });

  // ==========================================
  // DASHBOARD STATISTICS ENDPOINT
  // ==========================================
  
  app.get('/api/dashboard/stats', (req, res) => {
    const members = db.getMembers();
    const collections = db.getCollections();
    const expenses = db.getExpenses();
    const txns = db.getTransactions();
    const settings = db.getSettings();

    // Calculations
    const totalCollection = collections.reduce((sum, c) => sum + c.amount, 0);
    const totalExpenses = expenses.reduce((sum, e) => sum + e.amount, 0);
    const totalFundBalance = totalCollection - totalExpenses;
    const totalMembers = members.length;

    // Current month/year (July 2026 based on mock clock)
    const currentMonth = "July";
    const currentYear = 2026;

    const currentMonthCollections = collections.filter(c => c.month === currentMonth && c.year === currentYear);
    const currentMonthCollectionAmt = currentMonthCollections.reduce((sum, c) => sum + c.amount, 0);

    // Calculate Dues
    const { summaries } = db.calculateDues();
    const totalDue = summaries.reduce((sum, s) => sum + s.remainingDue, 0);

    // Recent lists
    const recentTransactions = txns.slice(0, 5);
    const recentExpenses = expenses.slice().reverse().slice(0, 5);

    res.json({
      totalFundBalance,
      totalCollection,
      totalExpenses,
      totalMembers,
      currentMonthCollection: currentMonthCollectionAmt,
      totalDue,
      recentTransactions,
      recentExpenses,
      currency: settings.currency,
      fundName: settings.fundName
    });
  });

  // ==========================================
  // MEMBER MANAGEMENT ENDPOINTS (ADMIN)
  // ==========================================
  
  app.get('/api/members', (req, res) => {
    res.json(db.getMembers());
  });

  app.post('/api/members', (req, res) => {
    try {
      const { name, phone, email, address, monthlyContribution, joinDate, status } = req.body;
      const adminUser = req.headers['x-user'] as string || 'Admin';

      if (!name || !phone || !email || !address || !monthlyContribution || !joinDate) {
         res.status(400).json({ error: 'All fields are required.' });
         return;
      }

      const newMember = db.addMember({
        name,
        phone,
        email,
        address,
        monthlyContribution: Number(monthlyContribution),
        joinDate,
        status: status || 'active'
      }, adminUser);

      res.status(201).json(newMember);
    } catch (e: any) {
      res.status(500).json({ error: e.message || 'Internal Server Error' });
    }
  });

  app.put('/api/members/:id', (req, res) => {
    try {
      const { id } = req.params;
      const data = req.body;
      const adminUser = req.headers['x-user'] as string || 'Admin';

      const updated = db.updateMember(id, data, adminUser);
      res.json(updated);
    } catch (e: any) {
      res.status(404).json({ error: e.message });
    }
  });

  app.delete('/api/members/:id', (req, res) => {
    try {
      const { id } = req.params;
      const adminUser = req.headers['x-user'] as string || 'Admin';

      db.deleteMember(id, adminUser);
      res.json({ success: true, message: `Member ${id} removed successfully.` });
    } catch (e: any) {
      res.status(404).json({ error: e.message });
    }
  });

  // ==========================================
  // FUND COLLECTION ENDPOINTS
  // ==========================================
  
  app.get('/api/collections', (req, res) => {
    res.json(db.getCollections());
  });

  app.post('/api/collections', (req, res) => {
    try {
      const { memberId, amount, paymentMethod, month, year } = req.body;
      const adminUser = req.headers['x-user'] as string || 'Admin';

      if (!memberId || amount === undefined || amount === null || !paymentMethod) {
         res.status(400).json({ error: 'Member, amount, and payment method are required.' });
         return;
      }

      const newPayment = db.addCollection({
        memberId,
        amount: Number(amount),
        paymentMethod,
        month: month ? String(month) : undefined,
        year: year ? Number(year) : undefined
      }, adminUser);

      res.status(201).json(newPayment);
    } catch (e: any) {
      res.status(400).json({ error: e.message });
    }
  });

  app.delete('/api/collections/:id', (req, res) => {
    try {
      const { id } = req.params;
      const adminUser = req.headers['x-user'] as string || 'Admin';

      db.deleteCollection(id, adminUser);
      res.json({ success: true, message: `Collection record ${id} removed successfully.` });
    } catch (e: any) {
      res.status(404).json({ error: e.message });
    }
  });

  // ==========================================
  // EXPENSE ENDPOINTS
  // ==========================================
  
  app.get('/api/expenses', (req, res) => {
    res.json(db.getExpenses());
  });

  app.post('/api/expenses', (req, res) => {
    try {
      const { title, description, amount, category, receipt } = req.body;
      const adminUser = req.headers['x-user'] as string || 'Admin';

      if (!title || !description || !amount || !category) {
         res.status(400).json({ error: 'Title, description, amount, and category are required.' });
         return;
      }

      const newExpense = db.addExpense({
        title,
        description,
        amount: Number(amount),
        category,
        receipt: receipt || null
      }, adminUser);

      res.status(201).json(newExpense);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  });

  app.delete('/api/expenses/:id', (req, res) => {
    try {
      const { id } = req.params;
      const adminUser = req.headers['x-user'] as string || 'Admin';

      db.deleteExpense(id, adminUser);
      res.json({ success: true, message: 'Expense deleted successfully.' });
    } catch (e: any) {
      res.status(404).json({ error: e.message });
    }
  });

  // ==========================================
  // DUE CALCULATOR ENDPOINTS
  // ==========================================
  
  app.get('/api/dues', (req, res) => {
    res.json(db.calculateDues());
  });

  // ==========================================
  // TRANSACTION HISTORY LEDGER
  // ==========================================
  
  app.get('/api/transactions', (req, res) => {
    res.json(db.getTransactions());
  });

  // ==========================================
  // NOTIFICATION MANAGEMENT
  // ==========================================
  
  app.get('/api/notifications', (req, res) => {
    res.json(db.getNotifications());
  });

  app.post('/api/notifications/read', (req, res) => {
    db.markNotificationsAsRead();
    res.json({ success: true });
  });

  // ==========================================
  // REPORTS GENERATOR ENDPOINT
  // ==========================================
  
  app.get('/api/reports', (req, res) => {
    const members = db.getMembers();
    const collections = db.getCollections();
    const expenses = db.getExpenses();
    const { summaries, breakdown } = db.calculateDues();
    
    // Overall Stats
    const totalPaid = collections.reduce((sum, c) => sum + c.amount, 0);
    const totalExpense = expenses.reduce((sum, e) => sum + e.amount, 0);
    const netBalance = totalPaid - totalExpense;

    // Category-wise expenses
    const categoryExpenses: Record<string, number> = {};
    expenses.forEach(e => {
      categoryExpenses[e.category] = (categoryExpenses[e.category] || 0) + e.amount;
    });

    // Monthly collection aggregation
    const monthlyCollections: Record<string, number> = {};
    collections.forEach(c => {
      const key = `${c.month} ${c.year}`;
      monthlyCollections[key] = (monthlyCollections[key] || 0) + c.amount;
    });

    // Monthly expense aggregation
    const monthlyExpenses: Record<string, number> = {};
    expenses.forEach(e => {
      // Extract month name from YYYY-MM-DD
      const dateParts = e.date.split('-');
      const monthIdx = parseInt(dateParts[1], 10) - 1;
      const monthName = path.join(process.cwd(), 'data') ? [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][monthIdx] : 'Unknown';
      const key = `${monthName} ${dateParts[0]}`;
      monthlyExpenses[key] = (monthlyExpenses[key] || 0) + e.amount;
    });

    res.json({
      summary: {
        totalPaid,
        totalExpense,
        netBalance,
        totalMembers: members.length
      },
      membersReport: summaries,
      duesBreakdown: breakdown,
      categoryExpenses,
      monthlyCollections,
      monthlyExpenses
    });
  });

  // ==========================================
  // SETTINGS & SYSTEM CONFIGURATION
  // ==========================================
  
  app.get('/api/settings', (req, res) => {
    res.json(db.getSettings());
  });

  app.put('/api/settings', (req, res) => {
    const adminUser = req.headers['x-user'] as string || 'Admin';
    const settings = req.body;
    const updated = db.updateSettings(settings, adminUser);
    res.json(updated);
  });

  // ==========================================
  // PROFILE UPDATE (USER PORTAL)
  // ==========================================
  
  app.put('/api/profile/:id', (req, res) => {
    try {
      const { id } = req.params;
      const { phone, email, address } = req.body;
      const user = db.getMemberById(id);

      if (!user) {
         res.status(404).json({ error: 'Member profile not found.' });
         return;
      }

      const updated = db.updateMember(id, { phone, email, address }, user.name);
      res.json(updated);
    } catch (e: any) {
      res.status(400).json({ error: e.message });
    }
  });

  // ==========================================
  // AUDIT LOGS ENDPOINT
  // ==========================================
  
  app.get('/api/logs', (req, res) => {
    res.json(db.getLogs());
  });

  // ==========================================
  // BACKUP & RESTORE ARCHIVES
  // ==========================================
  
  app.get('/api/database/backup', (req, res) => {
    const backupJson = db.backupDatabase();
    res.setHeader('Content-disposition', 'attachment; filename=fmf_database_backup.json');
    res.setHeader('Content-type', 'application/json');
    res.write(backupJson);
    res.end();
  });

  app.post('/api/database/restore', (req, res) => {
    try {
      const { backupData } = req.body;
      const adminUser = req.headers['x-user'] as string || 'Admin';

      if (!backupData) {
         res.status(400).json({ error: 'No backup file payload provided.' });
         return;
      }

      const success = db.restoreDatabase(JSON.stringify(backupData), adminUser);
      if (success) {
        res.json({ success: true, message: 'Database successfully restored.' });
      } else {
        res.status(400).json({ error: 'Invalid backup format. Ensure backup is a valid FMF export.' });
      }
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  });

  app.post('/api/database/reset', (req, res) => {
    const adminUser = req.headers['x-user'] as string || 'Admin';
    db.resetDatabase(adminUser);
    res.json({ success: true, message: 'Database reset to initial demo seeds.' });
  });

  // ==========================================
  // VITE DEVELOPMENT MIDDLEWARE & STATIC ASSETS
  // ==========================================
  
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  // Bind to port 3000 as strictly enforced in container regulations
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`FMF Full-Stack Server running on http://0.0.0.0:${PORT}`);
  });
}

startServer().catch((error) => {
  console.error('Critical failure starting Express + Vite server:', error);
});
