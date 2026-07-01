const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '', // Empty password for XAMPP default
  database: process.env.DB_NAME || 'projectflow_db',
  port: process.env.DB_PORT || 3306
};

// JWT Secret
if (!process.env.JWT_SECRET) {
  console.error("FATAL ERROR: JWT_SECRET environment variable is not defined.");
  process.exit(1);
}
const JWT_SECRET = process.env.JWT_SECRET;

// Database connection test
async function testConnection() {
  try {
    const connection = await mysql.createConnection(dbConfig);
    console.log('✅ Connected to MySQL database successfully!');
    await connection.end();
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    process.exit(1);
  }
}

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ message: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Admin middleware
const requireAdmin = async (req, res, next) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [users] = await connection.execute(
      'SELECT role FROM users WHERE user_id = ?',
      [req.user.userId]
    );
    await connection.end();

    if (users.length === 0 || users[0].role !== 'admin') {
      return res.status(403).json({ message: 'Admin privileges required' });
    }
    next();
  } catch (error) {
    console.error('Admin check error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Routes

// User Registration
app.post('/api/register', async (req, res) => {
  const { fullName, email, password } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Check if user already exists
    const [existingUsers] = await connection.execute(
      'SELECT user_id FROM users WHERE email = ?',
      [email]
    );

    if (existingUsers.length > 0) {
      await connection.end();
      return res.status(400).json({ message: 'User with this email already exists' });
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create unique username from email
    let baseUsername = email.split('@')[0];
    let username = baseUsername;
    let suffix = 1;
    let usernameExists = true;
    
    while(usernameExists) {
      const [existingUsernames] = await connection.execute(
        'SELECT user_id FROM users WHERE username = ?',
        [username]
      );
      if (existingUsernames.length > 0) {
        username = `${baseUsername}${suffix}`;
        suffix++;
      } else {
        usernameExists = false;
      }
    }

    // Insert new user
    const [result] = await connection.execute(
      'INSERT INTO users (username, password_hash, email, full_name, role) VALUES (?, ?, ?, ?, ?)',
      [username, hashedPassword, email, fullName, 'user']
    );

    await connection.end();

    res.status(201).json({ 
      message: 'User created successfully',
      userId: result.insertId 
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// User Login
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Find user by email
    const [users] = await connection.execute(
      'SELECT user_id, username, password_hash, email, full_name, avatar_url, role FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      await connection.end();
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const user = users[0];

    // Check password
    const passwordMatch = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatch) {
      await connection.end();
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.user_id, 
        email: user.email,
        role: user.role 
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    await connection.end();

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.user_id,
        username: user.username,
        email: user.email,
        fullName: user.full_name,
        avatarUrl: user.avatar_url,
        role: user.role
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Dashboard data
app.get('/api/dashboard', authenticateToken, async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Get assigned issues
    const [assignedIssues] = await connection.execute(`
      SELECT i.issue_key, i.summary, i.priority, i.due_date, 
             s.status_name, p.project_name
      FROM issues i 
      JOIN issue_statuses s ON i.status_id = s.status_id 
      JOIN projects p ON i.project_id = p.project_id 
      WHERE i.assignee_id = ? AND s.status_name != 'Done'
      ORDER BY i.due_date ASC 
      LIMIT 5
    `, [req.user.userId]);

    // Get projects
    const [projects] = await connection.execute(`
      SELECT p.project_key, p.project_name, p.updated_at,
             u.full_name as lead_name
      FROM projects p 
      LEFT JOIN users u ON p.lead_user_id = u.user_id 
      ORDER BY p.updated_at DESC 
      LIMIT 5
    `);

    // Get recent activity (comments)
    const [activity] = await connection.execute(`
      SELECT c.comment_text as details, c.created_at as activity_date,
             u.full_name, u.avatar_url, i.issue_key
      FROM comments c
      JOIN users u ON c.user_id = u.user_id
      JOIN issues i ON c.issue_id = i.issue_id
      ORDER BY c.created_at DESC
      LIMIT 5
    `);

    await connection.end();

    res.json({
      assignedIssues,
      projects,
      activity
    });

  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Get all projects
app.get('/api/projects', authenticateToken, async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    
    const [projects] = await connection.execute(`
      SELECT p.project_id, p.project_key, p.project_name, p.description, 
             p.created_at, p.updated_at, u.full_name as lead_name
      FROM projects p 
      LEFT JOIN users u ON p.lead_user_id = u.user_id 
      ORDER BY p.updated_at DESC
    `);

    await connection.end();
    res.json(projects);

  } catch (error) {
    console.error('Projects error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Get all issues
app.get('/api/issues', authenticateToken, async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    
    const [issues] = await connection.execute(`
      SELECT i.issue_key, i.summary, i.priority, i.due_date,
             s.status_name, p.project_name,
             assignee.full_name as assignee_name,
             reporter.full_name as reporter_name
      FROM issues i
      JOIN issue_statuses s ON i.status_id = s.status_id
      JOIN projects p ON i.project_id = p.project_id
      JOIN users reporter ON i.reporter_id = reporter.user_id
      LEFT JOIN users assignee ON i.assignee_id = assignee.user_id
      ORDER BY i.updated_at DESC
    `);

    await connection.end();
    res.json(issues);

  } catch (error) {
    console.error('Issues error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Create new issue
app.post('/api/issues', authenticateToken, async (req, res) => {
  const { projectKey, summary, description, priority } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Get project ID
    const [projects] = await connection.execute(
      'SELECT project_id FROM projects WHERE project_key = ?',
      [projectKey]
    );

    if (projects.length === 0) {
      await connection.end();
      return res.status(404).json({ message: 'Project not found' });
    }

    const projectId = projects[0].project_id;

    // Generate issue key
    const [issueCount] = await connection.execute(
      'SELECT COUNT(*) as count FROM issues WHERE project_id = ?',
      [projectId]
    );
    
    const issueNumber = issueCount[0].count + 1;
    const issueKey = `${projectKey}-${issueNumber.toString().padStart(3, '0')}`;

    // Insert new issue
    const [result] = await connection.execute(`
      INSERT INTO issues (project_id, issue_key, summary, description, issue_type_id, status_id, reporter_id, priority)
      VALUES (?, ?, ?, ?, 2, 1, ?, ?)
    `, [projectId, issueKey, summary, description || '', req.user.userId, priority]);

    await connection.end();

    res.status(201).json({ 
      message: 'Issue created successfully',
      issueId: result.insertId,
      issueKey: issueKey
    });

  } catch (error) {
    console.error('Create issue error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Get project board (Kanban)
app.get('/api/projects/:projectKey/board', authenticateToken, async (req, res) => {
  try {
    const { projectKey } = req.params;
    const connection = await mysql.createConnection(dbConfig);
    
    // Get project info
    const [projects] = await connection.execute(
      'SELECT project_id FROM projects WHERE project_key = ?',
      [projectKey]
    );

    if (projects.length === 0) {
      await connection.end();
      return res.status(404).json({ message: 'Project not found' });
    }

    const projectId = projects[0].project_id;

    // Get all statuses and their issues
    const [statuses] = await connection.execute(
      'SELECT status_id, status_name, status_order FROM issue_statuses ORDER BY status_order'
    );

    const boardData = [];

    for (const status of statuses) {
      const [issues] = await connection.execute(`
        SELECT i.issue_key, i.summary, i.priority,
               assignee.full_name as assignee_name,
               assignee.avatar_url as assignee_avatar
        FROM issues i
        LEFT JOIN users assignee ON i.assignee_id = assignee.user_id
        WHERE i.project_id = ? AND i.status_id = ?
        ORDER BY i.created_at DESC
      `, [projectId, status.status_id]);

      boardData.push({
        statusId: status.status_id,
        statusName: status.status_name,
        issues: issues
      });
    }

    await connection.end();
    res.json(boardData);

  } catch (error) {
    console.error('Board error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Get issue details
app.get('/api/issues/:issueKey', authenticateToken, async (req, res) => {
  try {
    const { issueKey } = req.params;
    const connection = await mysql.createConnection(dbConfig);
    
    // Get issue details
    const [issues] = await connection.execute(`
      SELECT i.*, s.status_name, p.project_key, p.project_name,
             assignee.full_name as assignee_name, assignee.avatar_url as assignee_avatar,
             reporter.full_name as reporter_name, reporter.avatar_url as reporter_avatar
      FROM issues i
      JOIN issue_statuses s ON i.status_id = s.status_id
      JOIN projects p ON i.project_id = p.project_id
      JOIN users reporter ON i.reporter_id = reporter.user_id
      LEFT JOIN users assignee ON i.assignee_id = assignee.user_id
      WHERE i.issue_key = ?
    `, [issueKey]);

    if (issues.length === 0) {
      await connection.end();
      return res.status(404).json({ message: 'Issue not found' });
    }

    const issue = issues[0];

    // Get comments
    const [comments] = await connection.execute(`
      SELECT c.comment_text, c.created_at, u.full_name, u.avatar_url
      FROM comments c
      JOIN users u ON c.user_id = u.user_id
      WHERE c.issue_id = ?
      ORDER BY c.created_at ASC
    `, [issue.issue_id]);

    issue.comments = comments;

    await connection.end();
    res.json(issue);

  } catch (error) {
    console.error('Issue details error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Update issue description
app.put('/api/issues/:issueKey', authenticateToken, async (req, res) => {
  const { issueKey } = req.params;
  const { description } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    const [result] = await connection.execute(
      'UPDATE issues SET description = ?, updated_at = CURRENT_TIMESTAMP WHERE issue_key = ?',
      [description, issueKey]
    );

    await connection.end();

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Issue not found' });
    }

    res.json({ message: 'Issue updated successfully' });

  } catch (error) {
    console.error('Update issue error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Update issue status
app.put('/api/issues/:issueKey/status', authenticateToken, async (req, res) => {
  try {
    const { issueKey } = req.params;
    const { statusId } = req.body;
    const connection = await mysql.createConnection(dbConfig);
    
    const [result] = await connection.execute(
      'UPDATE issues SET status_id = ?, updated_at = CURRENT_TIMESTAMP WHERE issue_key = ?',
      [statusId, issueKey]
    );

    await connection.end();

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Issue not found' });
    }

    res.json({ message: 'Issue status updated successfully' });

  } catch (error) {
    console.error('Update status error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Add comment to issue
app.post('/api/issues/:issueKey/comments', authenticateToken, async (req, res) => {
  const { issueKey } = req.params;
  const { comment } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Get issue ID
    const [issues] = await connection.execute(
      'SELECT issue_id FROM issues WHERE issue_key = ?',
      [issueKey]
    );

    if (issues.length === 0) {
      await connection.end();
      return res.status(404).json({ message: 'Issue not found' });
    }

    const issueId = issues[0].issue_id;

    // Insert comment
    await connection.execute(
      'INSERT INTO comments (issue_id, user_id, comment_text) VALUES (?, ?, ?)',
      [issueId, req.user.userId, comment]
    );

    await connection.end();

    res.status(201).json({ message: 'Comment added successfully' });

  } catch (error) {
    console.error('Add comment error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Get all users (Admin only)
app.get('/api/users', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);

    // Get all users
    const [users] = await connection.execute(`
      SELECT user_id, username, email, full_name, avatar_url, role, created_at
      FROM users 
      ORDER BY created_at DESC
    `);

    await connection.end();
    res.json(users);

  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Create new user (Admin only)
app.post('/api/users', authenticateToken, requireAdmin, async (req, res) => {
  const { fullName, email, password, role } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Check if user already exists
    const [existingUsers] = await connection.execute(
      'SELECT user_id FROM users WHERE email = ?',
      [email]
    );

    if (existingUsers.length > 0) {
      await connection.end();
      return res.status(400).json({ message: 'User with this email already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create unique username from email
    let baseUsername = email.split('@')[0];
    let username = baseUsername;
    let suffix = 1;
    let usernameExists = true;
    
    while(usernameExists) {
      const [existingUsernames] = await connection.execute(
        'SELECT user_id FROM users WHERE username = ?',
        [username]
      );
      if (existingUsernames.length > 0) {
        username = `${baseUsername}${suffix}`;
        suffix++;
      } else {
        usernameExists = false;
      }
    }

    // Insert new user
    const [result] = await connection.execute(
      'INSERT INTO users (username, password_hash, email, full_name, role) VALUES (?, ?, ?, ?, ?)',
      [username, hashedPassword, email, fullName, role]
    );

    await connection.end();

    res.status(201).json({ 
      message: 'User created successfully',
      userId: result.insertId 
    });

  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Update user (Admin only)
app.put('/api/users/:userId', authenticateToken, requireAdmin, async (req, res) => {
  const { userId } = req.params;
  const { fullName, email, role } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Update user
    const [result] = await connection.execute(
      'UPDATE users SET full_name = ?, email = ?, role = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?',
      [fullName, email, role, userId]
    );

    await connection.end();

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ message: 'User updated successfully' });

  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Delete user (Admin only)
app.delete('/api/users/:userId', authenticateToken, requireAdmin, async (req, res) => {
  const { userId } = req.params;

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Don't allow deleting yourself
    if (parseInt(userId) === req.user.userId) {
      await connection.end();
      return res.status(400).json({ message: 'Cannot delete your own account' });
    }

    // Delete user
    const [result] = await connection.execute(
      'DELETE FROM users WHERE user_id = ?',
      [userId]
    );

    await connection.end();

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ message: 'User deleted successfully' });

  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Update user profile
app.put('/api/profile', authenticateToken, async (req, res) => {
  const { fullName, email } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Update user profile
    const [result] = await connection.execute(
      'UPDATE users SET full_name = ?, email = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?',
      [fullName, email, req.user.userId]
    );

    // Get updated user data
    const [users] = await connection.execute(
      'SELECT user_id, username, email, full_name, avatar_url, role FROM users WHERE user_id = ?',
      [req.user.userId]
    );

    await connection.end();

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ 
      message: 'Profile updated successfully',
      user: {
        id: users[0].user_id,
        username: users[0].username,
        email: users[0].email,
        fullName: users[0].full_name,
        avatarUrl: users[0].avatar_url,
        role: users[0].role
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Change password
app.put('/api/profile/password', authenticateToken, async (req, res) => {
  const { currentPassword, newPassword } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);
    
    // Get current user
    const [users] = await connection.execute(
      'SELECT password_hash FROM users WHERE user_id = ?',
      [req.user.userId]
    );

    if (users.length === 0) {
      await connection.end();
      return res.status(404).json({ message: 'User not found' });
    }

    // Verify current password
    const passwordMatch = await bcrypt.compare(currentPassword, users[0].password_hash);

    if (!passwordMatch) {
      await connection.end();
      return res.status(400).json({ message: 'Current password is incorrect' });
    }

    // Hash new password
    const hashedNewPassword = await bcrypt.hash(newPassword, 10);

    // Update password
    await connection.execute(
      'UPDATE users SET password_hash = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?',
      [hashedNewPassword, req.user.userId]
    );

    await connection.end();

    res.json({ message: 'Password changed successfully' });

  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Get notifications (basic implementation)
app.get('/api/notifications', authenticateToken, async (req, res) => {
  try {
    // Basic notification system - you can expand this
    const notifications = [
      {
        id: 1,
        message: `Welcome to ProjectFlow, ${req.user.email}!`,
        type: 'info',
        read: false,
        created_at: new Date().toISOString()
      }
    ];

    res.json(notifications);

  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Mark notification as read
app.put('/api/notifications/:notificationId/read', authenticateToken, async (req, res) => {
  // Basic implementation - you can expand this
  res.json({ message: 'Notification marked as read' });
});

// Start server
app.listen(PORT, async () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  await testConnection();
});

module.exports = app;