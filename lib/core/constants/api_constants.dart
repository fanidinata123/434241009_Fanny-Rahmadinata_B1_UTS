class ApiConstants {
  static const String baseUrl = 'https://api.helpdesk.example.com/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh';

  // Tickets
  static const String tickets = '/tickets';
  static String ticketById(String id) => '/tickets/$id';
  static String ticketComments(String id) => '/tickets/$id/comments';
  static String ticketStatus(String id) => '/tickets/$id/status';
  static String ticketAssign(String id) => '/tickets/$id/assign';
  static String ticketAttachments(String id) => '/tickets/$id/attachments';

  // Dashboard
  static const String dashboardStats = '/dashboard/stats';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotifRead(String id) => '/notifications/$id/read';

  // Profile
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
}