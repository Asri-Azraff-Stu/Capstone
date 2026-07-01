import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// IMPORTANT: Replace with your computer's local IP address.
// For Android Emulator, you can often use 10.0.2.2
// For a physical device on the same Wi-Fi, use your computer's IP.
const String API_BASE_URL = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000/api');

// Data Models
class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
      role: json['role'],
    );
  }
}

class Project {
  final int? projectId;
  final String key;
  final String name;
  final String description;
  final String? leadName;
  final String? createdAt;
  final String? updatedAt;

  Project({
    this.projectId,
    required this.key,
    required this.name,
    required this.description,
    this.leadName,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectId: json['project_id'],
      key: json['project_key'],
      name: json['project_name'],
      description: json['description'] ?? '',
      leadName: json['lead_name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class Issue {
  final String key;
  final String summary;
  final String? description;
  final String status;
  final String priority;
  final String? assignee;
  final String? assigneeAvatar;
  final String? reporter;
  final String? reporterAvatar;
  final String? dueDate;
  final String projectName;
  final String? createdAt;
  final String? updatedAt;
  final List<Comment>? comments;

  Issue({
    required this.key,
    required this.summary,
    this.description,
    required this.status,
    required this.priority,
    this.assignee,
    this.assigneeAvatar,
    this.reporter,
    this.reporterAvatar,
    this.dueDate,
    required this.projectName,
    this.createdAt,
    this.updatedAt,
    this.comments,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      key: json['issue_key'],
      summary: json['summary'],
      description: json['description'],
      status: json['status_name'],
      priority: json['priority'],
      assignee: json['assignee_name'],
      assigneeAvatar: json['assignee_avatar'],
      reporter: json['reporter_name'],
      reporterAvatar: json['reporter_avatar'],
      dueDate: json['due_date'],
      projectName: json['project_name'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      comments: json['comments'] != null
          ? (json['comments'] as List).map((c) => Comment.fromJson(c)).toList()
          : null,
    );
  }
}

class Comment {
  final String text;
  final String createdAt;
  final String userName;
  final String? userAvatar;

  Comment({
    required this.text,
    required this.createdAt,
    required this.userName,
    this.userAvatar,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      text: json['comment_text'],
      createdAt: json['created_at'],
      userName: json['full_name'],
      userAvatar: json['avatar_url'],
    );
  }
}

class DashboardData {
  final List<Issue> assignedIssues;
  final List<Project> projects;
  final List<Activity> activity;

  DashboardData({
    required this.assignedIssues,
    required this.projects,
    required this.activity,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      assignedIssues: (json['assignedIssues'] as List)
          .map((i) => Issue.fromJson(i))
          .toList(),
      projects: (json['projects'] as List)
          .map((p) => Project.fromJson(p))
          .toList(),
      activity: (json['activity'] as List)
          .map((a) => Activity.fromJson(a))
          .toList(),
    );
  }
}

class Activity {
  final String details;
  final String activityDate;
  final String fullName;
  final String? avatarUrl;
  final String issueKey;

  Activity({
    required this.details,
    required this.activityDate,
    required this.fullName,
    this.avatarUrl,
    required this.issueKey,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      details: json['details'],
      activityDate: json['activity_date'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      issueKey: json['issue_key'],
    );
  }
}

class BoardColumn {
  final int statusId;
  final String statusName;
  final List<Issue> issues;

  BoardColumn({
    required this.statusId,
    required this.statusName,
    required this.issues,
  });

  factory BoardColumn.fromJson(Map<String, dynamic> json) {
    return BoardColumn(
      statusId: json['statusId'],
      statusName: json['statusName'],
      issues: (json['issues'] as List)
          .map((i) => Issue.fromJson(i))
          .toList(),
    );
  }
}

// Main App Setup
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const ProjectFlowApp(),
    ),
  );
}

class ProjectFlowApp extends StatelessWidget {
  const ProjectFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProjectFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA5E9)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
        elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// API Service
class ApiService {
  final String token;
  ApiService(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<T?> _handleResponse<T>(
    http.Response response,
    T Function(dynamic) fromJson,
  ) async {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return fromJson(data);
    } else if (response.statusCode == 401) {
      // Token expired, should logout
      throw Exception('Authentication required');
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'API Error');
    }
  }

  Future<List<T>> fetchList<T>(
    String endpoint, 
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/$endpoint'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch data');
    } catch (e) {
      print('Error fetching $endpoint: $e');
      rethrow;
    }
  }

  Future<T?> fetchSingle<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/$endpoint'),
        headers: _headers,
      );
      
      return await _handleResponse(response, (data) => fromJson(data));
    } catch (e) {
      print('Error fetching $endpoint: $e');
      rethrow;
    }
  }

  Future<DashboardData> fetchDashboard() async {
    final response = await http.get(
      Uri.parse('$API_BASE_URL/dashboard'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return DashboardData.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to fetch dashboard data');
  }

  Future<List<BoardColumn>> fetchBoard(String projectKey) async {
    final response = await http.get(
      Uri.parse('$API_BASE_URL/projects/$projectKey/board'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => BoardColumn.fromJson(item)).toList();
    }
    throw Exception('Failed to fetch board data');
  }

  Future<Issue> fetchIssueDetails(String issueKey) async {
    final response = await http.get(
      Uri.parse('$API_BASE_URL/issues/$issueKey'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return Issue.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to fetch issue details');
  }

  Future<bool> updateIssueStatus(String issueKey, int statusId) async {
    final response = await http.put(
      Uri.parse('$API_BASE_URL/issues/$issueKey/status'),
      headers: _headers,
      body: json.encode({'statusId': statusId}),
    );
    
    return response.statusCode == 200;
  }

  Future<bool> addComment(String issueKey, String comment) async {
    final response = await http.post(
      Uri.parse('$API_BASE_URL/issues/$issueKey/comments'),
      headers: _headers,
      body: json.encode({'comment': comment}),
    );
    
    return response.statusCode == 201;
  }

  Future<bool> updateIssueDescription(String issueKey, String description) async {
    final response = await http.put(
      Uri.parse('$API_BASE_URL/issues/$issueKey'),
      headers: _headers,
      body: json.encode({'description': description}),
    );
    
    return response.statusCode == 200;
  }

  Future<bool> createIssue({
    required String projectKey,
    required String summary,
    String? description,
    String priority = 'Medium',
  }) async {
    final response = await http.post(
      Uri.parse('$API_BASE_URL/issues'),
      headers: _headers,
      body: json.encode({
        'projectKey': projectKey,
        'summary': summary,
        'description': description,
        'priority': priority,
      }),
    );
    
    return response.statusCode == 201;
  }
}

// Authentication
class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  
  String? get token => _token;
  User? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _user?.role == 'admin';

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('authToken')) return;
    
    _token = prefs.getString('authToken');
    final userJson = prefs.getString('currentUser');
    if (userJson != null) {
      _user = User.fromJson(json.decode(userJson));
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', _token!);
        await prefs.setString('currentUser', json.encode(data['user']));
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}

// Screens

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Demo accounts
  final List<Map<String, String>> _demoAccounts = [
    {
      'email': 'asri.azraff@example.com',
      'password': 'AdminFlow#2025!',
      'role': 'Admin',
    },
    {
      'email': 'siti.nurhaliza@example.com',
      'password': 'UserPass@ProJ789',
      'role': 'User',
    },
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final success = await context.read<AuthProvider>().login(
      _emailController.text,
      _passwordController.text,
    );
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Failed. Please check your credentials.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  void _fillDemoAccount(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo and Title
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF0EA5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ProjectFlow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Sign in to your account',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty || !v.contains('@') 
                          ? 'Please enter a valid email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (v) => v!.isEmpty 
                          ? 'Password cannot be empty' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Sign In',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Demo Accounts
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Demo Accounts:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._demoAccounts.map((account) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _fillDemoAccount(
                          account['email']!, 
                          account['password']!,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${account['role']} Account',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                account['email']!,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Tap to use this account',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthProvider>().token!);
    _pages = [
      DashboardScreen(apiService: _apiService),
      ProjectsScreen(apiService: _apiService),
      IssuesScreen(apiService: _apiService),
      ProfileScreen(apiService: _apiService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProjectFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF0EA5E9),
        unselectedItemColor: const Color(0xFF64748B),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Issues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final ApiService apiService;
  const DashboardScreen({required this.apiService, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = widget.apiService.fetchDashboard();
  }

  void _refreshDashboard() {
    setState(() {
      _dashboardFuture = widget.apiService.fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return RefreshIndicator(
      onRefresh: () async => _refreshDashboard(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${user?.fullName ?? 'User'}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Here\'s what\'s happening with your projects today.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            FutureBuilder<DashboardData>(
              future: _dashboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        ElevatedButton(
                          onPressed: _refreshDashboard,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                final data = snapshot.data!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Assigned Issues
                    const Text(
                      'Your Assigned Issues',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    data.assignedIssues.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No assigned issues'),
                            ),
                          )
                        : Column(
                            children: data.assignedIssues.map((issue) => Card(
                              child: ListTile(
                                title: Text('${issue.key}: ${issue.summary}'),
                                subtitle: Text('Priority: ${issue.priority}'),
                                trailing: Chip(
                                  label: Text(issue.status),
                                  backgroundColor: _getStatusColor(issue.status),
                                ),
                                onTap: () => _navigateToIssueDetails(issue.key),
                              ),
                            )).toList(),
                          ),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Projects
                    const Text(
                      'Recent Projects',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    data.projects.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No projects available'),
                            ),
                          )
                        : Column(
                            children: data.projects.map((project) => Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF0EA5E9),
                                  child: Text(
                                    project.key.substring(0, 1),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(project.name),
                                subtitle: Text(project.description),
                                trailing: Text('Lead: ${project.leadName ?? 'Unassigned'}'),
                                onTap: () => _navigateToProjectBoard(project.key),
                              ),
                            )).toList(),
                          ),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Activity
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    data.activity.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No recent activity'),
                            ),
                          )
                        : Column(
                            children: data.activity.map((activity) => Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: activity.avatarUrl != null 
                                      ? NetworkImage(activity.avatarUrl!)
                                      : null,
                                  child: activity.avatarUrl == null 
                                      ? Text(activity.fullName.substring(0, 1))
                                      : null,
                                ),
                                title: Text(activity.fullName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Commented on ${activity.issueKey}',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      activity.details.length > 100 
                                          ? '${activity.details.substring(0, 100)}...'
                                          : activity.details,
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  _formatDateTime(activity.activityDate),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onTap: () => _navigateToIssueDetails(activity.issueKey),
                              ),
                            )).toList(),
                          ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to do':
        return Colors.grey.shade200;
      case 'in progress':
        return Colors.blue.shade200;
      case 'in review':
        return Colors.purple.shade200;
      case 'done':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  String _formatDateTime(String dateTime) {
    final date = DateTime.parse(dateTime);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  void _navigateToIssueDetails(String issueKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IssueDetailScreen(
          apiService: widget.apiService,
          issueKey: issueKey,
        ),
      ),
    );
  }

  void _navigateToProjectBoard(String projectKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KanbanScreen(
          apiService: widget.apiService,
          projectKey: projectKey,
        ),
      ),
    );
  }
}

class ProjectsScreen extends StatefulWidget {
  final ApiService apiService;
  const ProjectsScreen({required this.apiService, super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late Future<List<Project>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = widget.apiService.fetchList('projects', Project.fromJson);
  }

  void _refreshProjects() {
    setState(() {
      _projectsFuture = widget.apiService.fetchList('projects', Project.fromJson);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refreshProjects(),
      child: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _refreshProjects,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No projects found.'),
                ],
              ),
            );
          }
          
          final projects = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KanbanScreen(
                        apiService: widget.apiService,
                        projectKey: project.key,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                project.key,
                                style: const TextStyle(
                                  color: Color(0xFF0EA5E9),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          project.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Lead: ${project.leadName ?? 'Unassigned'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            if (project.updatedAt != null)
                              Text(
                                'Updated: ${_formatDate(project.updatedAt!)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }
}

class IssuesScreen extends StatefulWidget {
  final ApiService apiService;
  const IssuesScreen({required this.apiService, super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  late Future<List<Issue>> _issuesFuture;

  @override
  void initState() {
    super.initState();
    _issuesFuture = widget.apiService.fetchList('issues', Issue.fromJson);
  }

  void _refreshIssues() {
    setState(() {
      _issuesFuture = widget.apiService.fetchList('issues', Issue.fromJson);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refreshIssues(),
      child: FutureBuilder<List<Issue>>(
        future: _issuesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _refreshIssues,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No issues found.'),
                ],
              ),
            );
          }
          
          final issues = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IssueDetailScreen(
                        apiService: widget.apiService,
                        issueKey: issue.key,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${issue.key}: ${issue.summary}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(
                                issue.status,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: _getStatusColor(issue.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(issue.priority),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                issue.priority,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Assignee: ${issue.assignee ?? 'Unassigned'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              issue.projectName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to do':
        return Colors.grey.shade200;
      case 'in progress':
        return Colors.blue.shade200;
      case 'in review':
        return Colors.purple.shade200;
      case 'done':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red.shade200;
      case 'medium':
        return Colors.yellow.shade200;
      case 'low':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade200;
    }
  }
}

class KanbanScreen extends StatefulWidget {
  final ApiService apiService;
  final String projectKey;
  const KanbanScreen({
    required this.apiService,
    required this.projectKey,
    super.key,
  });

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  late Future<List<BoardColumn>> _boardFuture;

  @override
  void initState() {
    super.initState();
    _boardFuture = widget.apiService.fetchBoard(widget.projectKey);
  }

  void _refreshBoard() {
    setState(() {
      _boardFuture = widget.apiService.fetchBoard(widget.projectKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Board: ${widget.projectKey}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBoard,
          ),
        ],
      ),
      body: FutureBuilder<List<BoardColumn>>(
        future: _boardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _refreshBoard,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No board data found.'),
            );
          }
          
          final columns = snapshot.data!;
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columns.map((column) => Container(
                width: 300,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              column.statusName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${column.issues.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: column.issues.length,
                          itemBuilder: (context, index) {
                            final issue = column.issues[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => IssueDetailScreen(
                                      apiService: widget.apiService,
                                      issueKey: issue.key,
                                    ),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        issue.key,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0EA5E9),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        issue.summary,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(issue.priority),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              issue.priority,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (issue.assigneeAvatar != null)
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundImage: NetworkImage(
                                                issue.assigneeAvatar!,
                                              ),
                                            )
                                          else if (issue.assignee != null)
                                            CircleAvatar(
                                              radius: 12,
                                              child: Text(
                                                issue.assignee!.substring(0, 1),
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            )
                                          else
                                            const CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.grey,
                                              child: Icon(
                                                Icons.person,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          );
        },
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red.shade200;
      case 'medium':
        return Colors.yellow.shade200;
      case 'low':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade200;
    }
  }
}

class IssueDetailScreen extends StatefulWidget {
  final ApiService apiService;
  final String issueKey;

  const IssueDetailScreen({
    required this.apiService,
    required this.issueKey,
    super.key,
  });

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  late Future<Issue> _issueFuture;
  final _commentController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isEditingDescription = false;

  @override
  void initState() {
    super.initState();
    _issueFuture = widget.apiService.fetchIssueDetails(widget.issueKey);
  }

  void _refreshIssue() {
    setState(() {
      _issueFuture = widget.apiService.fetchIssueDetails(widget.issueKey);
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final success = await widget.apiService.addComment(
      widget.issueKey,
      _commentController.text.trim(),
    );

    if (success) {
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshIssue();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add comment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveDescription() async {
    final success = await widget.apiService.updateIssueDescription(
      widget.issueKey,
      _descriptionController.text,
    );

    if (success) {
      setState(() => _isEditingDescription = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshIssue();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update description'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.issueKey),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshIssue,
          ),
        ],
      ),
      body: FutureBuilder<Issue>(
        future: _issueFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _refreshIssue,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final issue = snapshot.data!;
          _descriptionController.text = issue.description ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Issue Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${issue.key}: ${issue.summary}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(issue.status),
                              backgroundColor: _getStatusColor(issue.status),
                            ),
                            Chip(
                              label: Text(issue.priority),
                              backgroundColor: _getPriorityColor(issue.priority),
                            ),
                            Chip(
                              label: Text(issue.projectName),
                              backgroundColor: Colors.blue.shade100,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Issue Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (issue.assigneeAvatar != null)
                              CircleAvatar(
                                backgroundImage: NetworkImage(issue.assigneeAvatar!),
                              )
                            else if (issue.assignee != null)
                              CircleAvatar(
                                child: Text(issue.assignee!.substring(0, 1)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow('Reporter', issue.reporter ?? 'Unknown'),
                        _buildDetailRow('Assignee', issue.assignee ?? 'Unassigned'),
                        if (issue.dueDate != null)
                          _buildDetailRow('Due Date', _formatDate(issue.dueDate!)),
                        _buildDetailRow('Created', _formatDateTime(issue.createdAt ?? '')),
                        _buildDetailRow('Updated', _formatDateTime(issue.updatedAt ?? '')),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_isEditingDescription)
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => setState(() => _isEditingDescription = false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: _saveDescription,
                                    child: const Text('Save'),
                                  ),
                                ],
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => setState(() => _isEditingDescription = true),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isEditingDescription)
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter description...',
                            ),
                            maxLines: 5,
                          )
                        else
                          Text(
                            issue.description?.isNotEmpty == true
                                ? issue.description!
                                : 'No description provided.',
                            style: const TextStyle(fontSize: 16),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Comments
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Add Comment
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Add a comment...',
                                ),
                                maxLines: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addComment,
                              child: const Text('Add'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Comments List
                        if (issue.comments == null || issue.comments!.isEmpty)
                          const Text('No comments yet.')
                        else
                          Column(
                            children: issue.comments!.map((comment) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: comment.userAvatar != null
                                        ? NetworkImage(comment.userAvatar!)
                                        : null,
                                    child: comment.userAvatar == null
                                        ? Text(comment.userName.substring(0, 1))
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              comment.userName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              _formatDateTime(comment.createdAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(comment.text),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to do':
        return Colors.grey.shade200;
      case 'in progress':
        return Colors.blue.shade200;
      case 'in review':
        return Colors.purple.shade200;
      case 'done':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red.shade200;
      case 'medium':
        return Colors.yellow.shade200;
      case 'low':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(String dateString) {
    if (dateString.isEmpty) return 'Unknown';
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _commentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class ProfileScreen extends StatelessWidget {
  final ApiService apiService;
  const ProfileScreen({required this.apiService, super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            user?.fullName.substring(0, 1) ?? 'U',
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? 'Unknown User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? 'No email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: user?.role == 'admin'
                          ? Colors.purple.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      user?.role.toUpperCase() ?? 'USER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: user?.role == 'admin'
                            ? Colors.purple.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Profile Actions
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implement settings screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon!')),
                    );
                  },
                ),
                if (auth.isAdmin) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Admin Panel'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Implement admin panel
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Admin panel coming soon!')),
                      );
                    },
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implement help screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'ProjectFlow',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(
                        Icons.task_alt,
                        size: 48,
                        color: Color(0xFF0EA5E9),
                      ),
                      children: const [
                        Text('A comprehensive project management solution.'),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              auth.logout();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}