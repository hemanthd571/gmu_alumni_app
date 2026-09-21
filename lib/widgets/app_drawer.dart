import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 25,
              left: 20,
              right: 20,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppConfig.primaryColor, Color(0xFF8B2D2D)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: AppConfig.secondaryColor,
                    foregroundImage: user?.profilePicture != null && user!.profilePicture!.isNotEmpty
                        ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(user.profilePicture))
                        : null,
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppConfig.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  user?.name ?? 'Alumni',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  user?.email ?? 'alumni@gmu.edu',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                if (user?.is_director ?? false) ...[
                  _buildDrawerItem(
                    context, 
                    'Director Dashboard', 
                    Icons.admin_panel_settings_rounded, 
                    '/director-dashboard'
                  ),
                  _buildDrawerItem(
                    context, 
                    'Alumni Feedback', 
                    Icons.feedback_rounded, 
                    '/director-feedback'
                  ),
                  _buildDrawerItem(
                    context, 
                    'Manage Events', 
                    Icons.event_rounded, 
                    '/director-events'
                  ),
                  const Divider(indent: 20, endIndent: 20),
                ],
                if (user?.is_spoc ?? false) ...[
                  _buildDrawerItem(
                    context, 
                    'Registration Requests', 
                    Icons.how_to_reg_rounded, 
                    '/spoc-dashboard'
                  ),
                  const Divider(indent: 20, endIndent: 20),
                ],
                if (!(user?.is_director ?? false))
                  _buildDrawerItem(context, 'Home', Icons.home_rounded, '/home'),
                _buildDrawerItem(context, 'Core Team', Icons.groups_rounded, '/core-team'),
                _buildDrawerItem(context, 'Noticeboard', Icons.campaign_rounded, '/noticeboard'),
                _buildDrawerItem(context, 'News Corner', Icons.newspaper_rounded, '/news'),
                _buildDrawerItem(context, 'Galleries', Icons.photo_library_rounded, '/galleries'),
                if (!(user?.is_director ?? false))
                  _buildDrawerItem(context, 'Calendar', Icons.event_available_rounded, '/events'),
                _buildDrawerItem(context, 'Jobs Portal', Icons.work_outline_rounded, '/jobs'),
                _buildDrawerItem(context, 'Proud Alumni', Icons.workspace_premium_rounded, '/proud-alumni'),
                const Divider(indent: 20, endIndent: 20, height: 30),
                _buildDrawerItem(context, 'Announcements', Icons.notifications_active_rounded, '/announcements'),
                _buildDrawerItem(context, 'Alumni Map', Icons.map_rounded, '/alumni-map'),
                const Divider(indent: 20, endIndent: 20, height: 30),
                if (!(user?.is_director ?? false) && !(user?.is_spoc ?? false)) ...[
                  _buildDrawerItem(context, 'Scan Event QR', Icons.qr_code_scanner_rounded, '/scan-qr'),
                  _buildDrawerItem(context, 'Share Feedback', Icons.feedback_rounded, '/feedback'),
                ],
                _buildDrawerItem(context, 'My Profile', Icons.person_rounded, '/profile'),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    final bool isSelected = GoRouterState.of(context).uri.toString() == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: AppConfig.primaryColor.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon, 
          color: isSelected ? AppConfig.primaryColor : Colors.grey[700],
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppConfig.primaryColor : Colors.grey[800],
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          context.push(route);
        },
      ),
    );
  }
}

