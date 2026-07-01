document.addEventListener('DOMContentLoaded', () => {
    // Authentication & Configuration
    const currentUser = JSON.parse(localStorage.getItem('currentUser'));
    const authToken = localStorage.getItem('authToken');

    if (!currentUser || !authToken) {
        window.location.href = 'login.html';
        return;
    }
    
    const API_BASE_URL = 'http://localhost:3000/api';
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
    };

    // DOM Element Selectors
    const mainContent = document.querySelector('main');
    const userAvatar = document.getElementById('user-avatar');
    const mobileUserAvatar = document.getElementById('mobile-user-avatar');
    const mobileUserName = document.getElementById('mobile-user-name');
    const mobileUserEmail = document.getElementById('mobile-user-email');
    const welcomeMessage = document.querySelector('.welcome-message');
    
    const mobileMenuButton = document.getElementById('mobileMenuButton');
    const mobileMenu = document.getElementById('mobile-menu');
    const userMenuButton = document.getElementById('userMenuButton');
    const userMenuDropdown = document.getElementById('userMenuDropdown');
    const createIssueBtn = document.getElementById('createIssueBtn');

    // Initialize user interface
    initializeUserInterface();

    // API Fetching Functions
    
    async function apiFetch(url, options = {}) {
        try {
            const response = await fetch(url, { headers, ...options });
            if (response.status === 401 || response.status === 403) {
                handleLogout();
            }
            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.message || 'An API error occurred.');
            }
            if (response.status === 204 || response.headers.get('content-length') === '0') {
                return null;
            }
            return response.json();
        } catch (error) {
            console.error('API Fetch Error:', error);
            displayTemporaryMessage(error.message, 'bg-red-500');
            return null;
        }
    }

    async function fetchDashboardData() {
        const data = await apiFetch(`${API_BASE_URL}/dashboard`);
        if (data) renderDashboard(data);
    }

    async function fetchProjects() {
        const projects = await apiFetch(`${API_BASE_URL}/projects`);
        if (projects) renderProjects(projects);
    }
    
    async function fetchAllIssues() {
        const issues = await apiFetch(`${API_BASE_URL}/issues`);
        if (issues) renderIssuesTable(issues);
    }

    async function fetchBoardData(projectKey) {
        const boardData = await apiFetch(`${API_BASE_URL}/projects/${projectKey}/board`);
        if (boardData) renderKanbanBoard(boardData);
    }

    async function fetchIssueDetails(issueKey) {
        const issue = await apiFetch(`${API_BASE_URL}/issues/${issueKey}`);
        if (issue) renderIssueDetails(issue);
    }

    async function updateIssueStatus(issueKey, newStatusId) {
        const url = `${API_BASE_URL}/issues/${issueKey}/status`;
        const options = {
            method: 'PUT',
            body: JSON.stringify({ statusId: newStatusId })
        };
        const result = await apiFetch(url, options);
        if (result) {
            displayTemporaryMessage(result.message, 'bg-green-500');
        }
    }

    async function fetchUsers() {
        if (currentUser.role !== 'admin') return;
        const users = await apiFetch(`${API_BASE_URL}/users`);
        if (users) renderUsers(users);
    }

    // HTML Rendering Functions

    function renderDashboard({ assignedIssues, projects, activity }) {
        const assignedList = document.getElementById('assigned-issues-list');
        const projectsList = document.getElementById('dashboard-projects-list');
        const activityList = document.getElementById('recent-activity-list');

        assignedList.innerHTML = assignedIssues.length > 0 ? assignedIssues.map(issue => `
            <div class="p-3 bg-slate-50 rounded-md hover:bg-slate-100 transition-colors cursor-pointer issue-card" data-issue-id="${issue.issue_key}">
                <div class="flex justify-between items-start">
                    <p class="text-sm font-medium text-slate-800">${issue.issue_key}: ${issue.summary}</p>
                    <span class="text-xs bg-yellow-100 text-yellow-700 px-2 py-0.5 rounded-full">${issue.status_name}</span>
                </div>
                <div class="flex items-center justify-between text-xs text-slate-500 mt-1">
                    <span>${getPriorityIcon(issue.priority)} ${issue.priority}</span>
                    <span>${formatDate(issue.due_date)}</span>
                </div>
            </div>
        `).join('') : '<p class="text-slate-500 text-sm">No assigned issues</p>';

        projectsList.innerHTML = projects.length > 0 ? projects.map(project => `
            <div class="p-3 bg-slate-50 rounded-md hover:bg-slate-100 transition-colors cursor-pointer project-card" data-project-key="${project.project_key}">
                <p class="text-sm font-medium text-slate-800">${project.project_name}</p>
                <p class="text-xs text-slate-500 mt-1">Lead: ${project.lead_name || 'Unassigned'}</p>
            </div>
        `).join('') : '<p class="text-slate-500 text-sm">No projects</p>';

        activityList.innerHTML = activity.length > 0 ? activity.map(item => `
            <li class="flex items-start space-x-3">
                <img class="h-8 w-8 rounded-full bg-slate-300" src="${item.avatar_url || 'https://placehold.co/32x32/64748B/E2E8F0?text=U'}" alt="">
                <div class="flex-1 min-w-0">
                    <p class="text-sm text-slate-900">
                        <span class="font-medium">${item.full_name}</span> commented on
                        <span class="font-medium text-sky-600 cursor-pointer issue-link" data-issue-key="${item.issue_key}">${item.issue_key}</span>
                    </p>
                    <p class="text-sm text-slate-500">${item.details.substring(0, 100)}${item.details.length > 100 ? '...' : ''}</p>
                    <p class="text-xs text-slate-400 mt-1">${formatDateTime(item.activity_date)}</p>
                </div>
            </li>
        `).join('') : '<li class="text-slate-500 text-sm">No recent activity</li>';

        // Add event listeners
        document.querySelectorAll('.issue-card, .issue-link').forEach(element => {
            element.addEventListener('click', (e) => {
                const issueKey = e.currentTarget.dataset.issueId || e.currentTarget.dataset.issueKey;
                showIssueDetails(issueKey);
            });
        });

        document.querySelectorAll('.project-card').forEach(element => {
            element.addEventListener('click', (e) => {
                const projectKey = e.currentTarget.dataset.projectKey;
                showProjectBoard(projectKey);
            });
        });
    }

    function renderProjects(projects) {
        const container = document.getElementById('projects-list-container');
        container.innerHTML = projects.map(project => `
            <div class="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow cursor-pointer project-card" data-project-key="${project.project_key}">
                <div class="flex items-center justify-between mb-4">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-sky-100 text-sky-800">
                        ${project.project_key}
                    </span>
                    <i class="fas fa-folder text-slate-400"></i>
                </div>
                <h3 class="text-lg font-semibold text-slate-900 mb-2">${project.project_name}</h3>
                <p class="text-slate-600 text-sm mb-4">${project.description || 'No description available'}</p>
                <div class="flex items-center justify-between text-xs text-slate-500">
                    <span>Lead: ${project.lead_name || 'Unassigned'}</span>
                    <span>Updated: ${formatDate(project.updated_at)}</span>
                </div>
            </div>
        `).join('');

        // Add event listeners
        document.querySelectorAll('.project-card').forEach(element => {
            element.addEventListener('click', (e) => {
                const projectKey = e.currentTarget.dataset.projectKey;
                showProjectBoard(projectKey);
            });
        });
    }

    function renderIssuesTable(issues) {
        const tbody = document.getElementById('issues-table-body');
        
        if (issues.length === 0) {
            tbody.innerHTML = '<div class="p-8 text-center text-slate-500">No issues found</div>';
            return;
        }

        const tableHTML = `
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-slate-200">
                    <thead class="bg-slate-50">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Issue</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Status</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Priority</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Assignee</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Project</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Due Date</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-slate-200">
                        ${issues.map(issue => `
                            <tr class="hover:bg-slate-50 cursor-pointer issue-row" data-issue-key="${issue.issue_key}">
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-slate-900">${issue.issue_key}</div>
                                    <div class="text-sm text-slate-500">${issue.summary}</div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(issue.status_name)}">
                                        ${issue.status_name}
                                    </span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
                                    ${getPriorityIcon(issue.priority)} ${issue.priority}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
                                    ${issue.assignee_name || 'Unassigned'}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
                                    ${issue.project_name}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
                                    ${formatDate(issue.due_date)}
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;

        tbody.innerHTML = tableHTML;

        // Add event listeners
        document.querySelectorAll('.issue-row').forEach(row => {
            row.addEventListener('click', (e) => {
                const issueKey = e.currentTarget.dataset.issueKey;
                showIssueDetails(issueKey);
            });
        });
    }

    function renderKanbanBoard(boardData) {
        const board = document.getElementById('kanban-board');
        board.innerHTML = boardData.map(column => `
            <div class="kanban-column bg-slate-100 p-4 rounded-lg min-w-72 max-w-72" data-status-id="${column.statusId}">
                <h3 class="font-semibold text-slate-700 mb-4 flex items-center justify-between">
                    ${column.statusName}
                    <span class="bg-slate-200 text-slate-600 text-xs px-2 py-1 rounded-full">${column.issues.length}</span>
                </h3>
                <div class="space-y-3 kanban-issues">
                    ${column.issues.map(issue => `
                        <div class="bg-white p-3 rounded-md shadow-sm hover:shadow-md transition-shadow cursor-pointer kanban-issue" 
                             data-issue-key="${issue.issue_key}" data-status-id="${column.statusId}">
                            <p class="text-sm font-medium text-slate-900 mb-2">${issue.issue_key}</p>
                            <p class="text-sm text-slate-600 mb-3">${issue.summary}</p>
                            <div class="flex items-center justify-between">
                                <span class="text-xs ${getPriorityColor(issue.priority)} px-2 py-1 rounded">
                                    ${getPriorityIcon(issue.priority)} ${issue.priority}
                                </span>
                                ${issue.assignee_avatar ? `
                                    <img class="h-6 w-6 rounded-full" src="${issue.assignee_avatar}" alt="${issue.assignee_name}" title="${issue.assignee_name}">
                                ` : '<div class="h-6 w-6 rounded-full bg-slate-300" title="Unassigned"></div>'}
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
        `).join('');

        // Make issues draggable
        initializeDragAndDrop();

        // Add click handlers for issue details
        document.querySelectorAll('.kanban-issue').forEach(issue => {
            issue.addEventListener('click', (e) => {
                const issueKey = e.currentTarget.dataset.issueKey;
                showIssueDetails(issueKey);
            });
        });
    }

    function renderIssueDetails(issue) {
        const section = document.getElementById('issue-detail');
        section.innerHTML = `
            <div class="max-w-4xl mx-auto">
                <div class="bg-white rounded-lg shadow-md">
                    <div class="p-6 border-b border-slate-200">
                        <div class="flex items-center justify-between mb-4">
                            <h1 class="text-2xl font-bold text-slate-900">${issue.issue_key}: ${issue.summary}</h1>
                            <button onclick="showSection('dashboard')" class="text-slate-500 hover:text-slate-700">
                                <i class="fas fa-times text-xl"></i>
                            </button>
                        </div>
                        <div class="flex flex-wrap gap-4 text-sm">
                            <span class="inline-flex px-2 py-1 rounded-full ${getStatusColor(issue.status_name)}">
                                ${issue.status_name}
                            </span>
                            <span class="${getPriorityColor(issue.priority)} px-2 py-1 rounded">
                                ${getPriorityIcon(issue.priority)} ${issue.priority}
                            </span>
                            <span class="text-slate-600">Project: ${issue.project_name}</span>
                            <span class="text-slate-600">Due: ${formatDate(issue.due_date)}</span>
                        </div>
                    </div>
                    
                    <div class="p-6">
                        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                            <div class="lg:col-span-2">
                                <div class="mb-6">
                                    <h3 class="text-lg font-semibold mb-3">Description</h3>
                                    <div class="prose prose-sm max-w-none">
                                        <textarea id="issue-description" class="w-full p-3 border border-slate-300 rounded-md resize-none" rows="6">${issue.description || ''}</textarea>
                                        <button id="save-description" class="mt-2 bg-sky-500 text-white px-4 py-2 rounded-md hover:bg-sky-600 transition-colors">
                                            Save Description
                                        </button>
                                    </div>
                                </div>
                                
                                <div>
                                    <h3 class="text-lg font-semibold mb-3">Comments</h3>
                                    <div id="comments-list" class="space-y-4 mb-4">
                                        ${issue.comments && issue.comments.length > 0 ? issue.comments.map(comment => `
                                            <div class="flex space-x-3">
                                                <img class="h-8 w-8 rounded-full" src="${comment.avatar_url || 'https://placehold.co/32x32/64748B/E2E8F0?text=U'}" alt="">
                                                <div class="flex-1">
                                                    <div class="bg-slate-50 rounded-lg p-3">
                                                        <div class="flex items-center justify-between mb-1">
                                                            <span class="font-medium text-sm">${comment.full_name}</span>
                                                            <span class="text-xs text-slate-500">${formatDateTime(comment.created_at)}</span>
                                                        </div>
                                                        <p class="text-sm text-slate-700">${comment.comment_text}</p>
                                                    </div>
                                                </div>
                                            </div>
                                        `).join('') : '<p class="text-slate-500 text-sm">No comments yet</p>'}
                                    </div>
                                    
                                    <div class="flex space-x-3">
                                        <img class="h-8 w-8 rounded-full" src="${currentUser.avatarUrl || 'https://placehold.co/32x32/64748B/E2E8F0?text=U'}" alt="">
                                        <div class="flex-1">
                                            <textarea id="new-comment" placeholder="Add a comment..." class="w-full p-3 border border-slate-300 rounded-md resize-none" rows="3"></textarea>
                                            <button id="add-comment" class="mt-2 bg-sky-500 text-white px-4 py-2 rounded-md hover:bg-sky-600 transition-colors">
                                                Add Comment
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="space-y-6">
                                <div>
                                    <h4 class="font-semibold text-slate-700 mb-3">Details</h4>
                                    <div class="space-y-3 text-sm">
                                        <div class="flex justify-between">
                                            <span class="text-slate-500">Reporter:</span>
                                            <span class="flex items-center">
                                                <img class="h-5 w-5 rounded-full mr-2" src="${issue.reporter_avatar || 'https://placehold.co/20x20/64748B/E2E8F0?text=R'}" alt="">
                                                ${issue.reporter_name}
                                            </span>
                                        </div>
                                        <div class="flex justify-between">
                                            <span class="text-slate-500">Assignee:</span>
                                            <span class="flex items-center">
                                                ${issue.assignee_name ? `
                                                    <img class="h-5 w-5 rounded-full mr-2" src="${issue.assignee_avatar || 'https://placehold.co/20x20/64748B/E2E8F0?text=A'}" alt="">
                                                    ${issue.assignee_name}
                                                ` : 'Unassigned'}
                                            </span>
                                        </div>
                                        <div class="flex justify-between">
                                            <span class="text-slate-500">Created:</span>
                                            <span>${formatDateTime(issue.created_at)}</span>
                                        </div>
                                        <div class="flex justify-between">
                                            <span class="text-slate-500">Updated:</span>
                                            <span>${formatDateTime(issue.updated_at)}</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Add event handlers
        document.getElementById('save-description').addEventListener('click', () => {
            saveIssueDescription(issue.issue_key);
        });

        document.getElementById('add-comment').addEventListener('click', () => {
            addComment(issue.issue_key);
        });
    }

    // Utility Functions

    function initializeUserInterface() {
        // Set user info in UI
        if (welcomeMessage) welcomeMessage.textContent = currentUser.fullName;
        if (userAvatar) userAvatar.src = currentUser.avatarUrl || 'https://placehold.co/40x40/64748B/E2E8F0?text=U';
        if (mobileUserAvatar) mobileUserAvatar.src = currentUser.avatarUrl || 'https://placehold.co/40x40/64748B/E2E8F0?text=U';
        if (mobileUserName) mobileUserName.textContent = currentUser.fullName;
        if (mobileUserEmail) mobileUserEmail.textContent = currentUser.email;

        // Set current year in footer
        document.getElementById('currentYear').textContent = new Date().getFullYear();

        // Initialize event listeners
        initializeEventListeners();
        
        // Show dashboard by default
        showSection('dashboard');
    }

    function initializeEventListeners() {
        // Mobile menu toggle
        if (mobileMenuButton) {
            mobileMenuButton.addEventListener('click', () => {
                mobileMenu.classList.toggle('hidden');
            });
        }

        // User menu toggle
        if (userMenuButton) {
            userMenuButton.addEventListener('click', (e) => {
                e.stopPropagation();
                userMenuDropdown.classList.toggle('hidden');
            });
        }

        // Close user menu when clicking outside
        document.addEventListener('click', () => {
            if (userMenuDropdown && !userMenuDropdown.classList.contains('hidden')) {
                userMenuDropdown.classList.add('hidden');
            }
        });

        // Navigation links
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const href = link.getAttribute('href');
                if (href && href.startsWith('#')) {
                    const section = href.substring(1);
                    showSection(section);
                }
            });
        });

        // Logo click
        document.querySelector('.site-logo').addEventListener('click', (e) => {
            e.preventDefault();
            showSection('dashboard');
        });

        // Create issue button
        if (createIssueBtn) {
            createIssueBtn.addEventListener('click', showCreateIssueModal);
        }

        // Logout buttons
        document.getElementById('logout-button').addEventListener('click', handleLogout);
        document.getElementById('mobile-logout-button').addEventListener('click', handleLogout);

        // Profile forms
        const profileForm = document.getElementById('profileForm');
        if (profileForm) {
            profileForm.addEventListener('submit', handleProfileUpdate);
        }
        const passwordForm = document.getElementById('passwordForm');
        if (passwordForm) {
            passwordForm.addEventListener('submit', handlePasswordUpdate);
        }
    }

    function showSection(sectionName) {
        // Hide all sections
        document.querySelectorAll('.app-section').forEach(section => {
            section.style.display = 'none';
        });

        // Show selected section
        const targetSection = document.getElementById(sectionName);
        if (targetSection) {
            targetSection.style.display = 'block';
            
            // Load data based on section
            switch (sectionName) {
                case 'dashboard':
                    fetchDashboardData();
                    break;
                case 'projects':
                    fetchProjects();
                    break;
                case 'issues':
                    fetchAllIssues();
                    break;
                case 'boards':
                    // Default to first project or show selection
                    break;
                case 'profile':
                    loadProfileData();
                    break;
            }
        }

        // Update navigation active states
        updateNavigationStates(sectionName);
        
        // Close mobile menu
        if (mobileMenu) mobileMenu.classList.add('hidden');
    }

    function updateNavigationStates(activeSection) {
        document.querySelectorAll('.nav-link').forEach(link => {
            const href = link.getAttribute('href');
            if (href === `#${activeSection}`) {
                link.classList.add('bg-slate-900', 'text-white');
                link.classList.remove('text-slate-300');
            } else {
                link.classList.remove('bg-slate-900', 'text-white');
                link.classList.add('text-slate-300');
            }
        });
    }

    function showProjectBoard(projectKey) {
        document.getElementById('boardProjectName').textContent = projectKey;
        showSection('boards');
        fetchBoardData(projectKey);
    }

    function showIssueDetails(issueKey) {
        showSection('issue-detail');
        fetchIssueDetails(issueKey);
    }

    function showCreateIssueModal() {
        // Simple prompt-based issue creation for now
        const projectKey = prompt('Enter project key (e.g., PROJ-A):');
        const summary = prompt('Enter issue summary:');
        const description = prompt('Enter issue description (optional):');
        const priority = prompt('Enter priority (Low/Medium/High):', 'Medium');

        if (projectKey && summary) {
            createIssue({ projectKey, summary, description, priority });
        }
    }

    async function createIssue(issueData) {
        const result = await apiFetch(`${API_BASE_URL}/issues`, {
            method: 'POST',
            body: JSON.stringify(issueData)
        });

        if (result) {
            displayTemporaryMessage(`Issue ${result.issueKey} created successfully!`, 'bg-green-500');
            // Refresh current view
            const currentSection = document.querySelector('.app-section[style*="block"]');
            if (currentSection) {
                const sectionId = currentSection.id;
                showSection(sectionId);
            }
        }
    }

    async function saveIssueDescription(issueKey) {
        const description = document.getElementById('issue-description').value;
        const result = await apiFetch(`${API_BASE_URL}/issues/${issueKey}`, {
            method: 'PUT',
            body: JSON.stringify({ description })
        });

        if (result) {
            displayTemporaryMessage('Description saved successfully!', 'bg-green-500');
        }
    }

    async function addComment(issueKey) {
        const commentText = document.getElementById('new-comment').value.trim();
        if (!commentText) return;

        const result = await apiFetch(`${API_BASE_URL}/issues/${issueKey}/comments`, {
            method: 'POST',
            body: JSON.stringify({ comment: commentText })
        });

        if (result) {
            document.getElementById('new-comment').value = '';
            displayTemporaryMessage('Comment added successfully!', 'bg-green-500');
            // Refresh issue details
            setTimeout(() => fetchIssueDetails(issueKey), 500);
        }
    }

    function initializeDragAndDrop() {
        document.querySelectorAll('.kanban-issues').forEach(column => {
            new Sortable(column, {
                group: 'shared',
                animation: 150,
                onEnd: function(evt) {
                    const issueKey = evt.item.dataset.issueKey;
                    const newStatusId = evt.to.parentElement.dataset.statusId;
                    updateIssueStatus(issueKey, newStatusId);
                }
            });
        });
    }

    function handleLogout() {
        localStorage.removeItem('currentUser');
        localStorage.removeItem('authToken');
        window.location.href = 'login.html';
    }

    function loadProfileData() {
        const fullNameInput = document.getElementById('profileFullName');
        const emailInput = document.getElementById('profileEmail');
        if (fullNameInput && emailInput) {
            fullNameInput.value = currentUser.fullName || '';
            emailInput.value = currentUser.email || '';
        }
    }

    async function handleProfileUpdate(e) {
        e.preventDefault();
        const fullName = document.getElementById('profileFullName').value;
        const email = document.getElementById('profileEmail').value;
        
        const result = await apiFetch(`${API_BASE_URL}/profile`, {
            method: 'PUT',
            body: JSON.stringify({ fullName, email })
        });

        if (result) {
            displayTemporaryMessage('Profile updated successfully!', 'bg-green-500');
            Object.assign(currentUser, result.user);
            localStorage.setItem('currentUser', JSON.stringify(currentUser));
            initializeUserInterface();
        }
    }

    async function handlePasswordUpdate(e) {
        e.preventDefault();
        const currentPassword = document.getElementById('currentPassword').value;
        const newPassword = document.getElementById('newPassword').value;
        const confirmNewPassword = document.getElementById('confirmNewPassword').value;

        if (newPassword !== confirmNewPassword) {
            displayTemporaryMessage('New passwords do not match!', 'bg-red-500');
            return;
        }

        const result = await apiFetch(`${API_BASE_URL}/profile/password`, {
            method: 'PUT',
            body: JSON.stringify({ currentPassword, newPassword })
        });

        if (result) {
            displayTemporaryMessage('Password changed successfully!', 'bg-green-500');
            document.getElementById('passwordForm').reset();
        }
    }

    function displayTemporaryMessage(message, bgColor = 'bg-blue-500') {
        const messageDiv = document.createElement('div');
        messageDiv.className = `fixed top-4 right-4 ${bgColor} text-white px-6 py-3 rounded-lg shadow-lg z-50 transition-opacity`;
        messageDiv.textContent = message;
        
        document.body.appendChild(messageDiv);
        
        setTimeout(() => {
            messageDiv.style.opacity = '0';
            setTimeout(() => messageDiv.remove(), 300);
        }, 3000);
    }

    // Helper Functions

    function getPriorityIcon(priority) {
        const icons = {
            'High': '<i class="fas fa-arrow-up text-red-500"></i>',
            'Medium': '<i class="fas fa-arrow-right text-yellow-500"></i>',
            'Low': '<i class="fas fa-arrow-down text-green-500"></i>'
        };
        return icons[priority] || icons['Medium'];
    }

    function getPriorityColor(priority) {
        const colors = {
            'High': 'bg-red-100 text-red-700',
            'Medium': 'bg-yellow-100 text-yellow-700',
            'Low': 'bg-green-100 text-green-700'
        };
        return colors[priority] || colors['Medium'];
    }

    function getStatusColor(status) {
        const colors = {
            'To Do': 'bg-slate-100 text-slate-700',
            'In Progress': 'bg-blue-100 text-blue-700',
            'In Review': 'bg-purple-100 text-purple-700',
            'Done': 'bg-green-100 text-green-700'
        };
        return colors[status] || colors['To Do'];
    }

    function formatDate(dateString) {
        if (!dateString) return 'No date';
        return new Date(dateString).toLocaleDateString();
    }

    function formatDateTime(dateString) {
        if (!dateString) return 'Unknown';
        return new Date(dateString).toLocaleString();
    }
});