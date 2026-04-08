import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class AdCard extends StatelessWidget {
  final String adId;
  final Map<String, dynamic> ad;

  const AdCard({super.key, required this.adId, required this.ad});

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final postDate = DateTime(date.year, date.month, date.day);
    if (postDate == today) return l10n.postedToday;
    if (postDate == yesterday) return l10n.postedYesterday;
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.statusPending;
      case 'completed':
        return l10n.statusCompleted;
      case 'active':
        return l10n.statusActive;
      case 'inactive':
        return l10n.statusInactive;
      case 'assigned':
        return l10n.statusAssigned;
      case 'approved':
        return l10n.statusApproved;
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        return const Color(0xFF13B94B);
      case 'assigned':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF9E9E9E);
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String title = ad['title_en'] ?? ad['title_ur'] ?? 'Untitled';
    final String description =
        ad['description_en'] ?? ad['description_ur'] ?? '';
    final String location = ad['Location'] ?? ad['location'] ?? '';
    final String status =
        ad['status'] ?? (ad['isActive'] == true ? 'Active' : 'Inactive');
    final Timestamp? ts = ad['createdAt'] as Timestamp?;
    final String dateText =
        ts != null ? _formatDate(ts.toDate().toLocal(), l10n) : '';
    final Color sColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _statusColor(status), width: 0.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top accent bar ──────────────────────────────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: sColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: sColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          status.toLowerCase() == 'completed'
                              ? Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: sColor,
                              )
                              : Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: sColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          const SizedBox(width: 5),
                          Text(
                            _getLocalizedStatus(status, l10n),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: sColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // ── Location + date ───────────────────────────────────
                Row(
                  children: [
                    if (location.isNotEmpty) ...[
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (dateText.isNotEmpty) ...[
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // ── Divider ───────────────────────────────────────────
                Divider(color: Colors.grey[100], height: 1),
                const SizedBox(height: 12),

                // ── Action buttons ────────────────────────────────────
                Row(
                  children: [
                    // Edit
                    _ActionButton(
                      label: l10n.edit,
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF13B94B),
                      outlined: true,
                      onTap:
                          () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.editComingSoon)),
                          ),
                    ),
                    const SizedBox(width: 8),
                    // Requests
                    _ActionButton(
                      label: l10n.requests,
                      icon: Icons.people_outline_rounded,
                      color: const Color(0xFF13B94B),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            '/job-poster-requests',
                            arguments: {'jobId': adId},
                          ),
                    ),
                    const SizedBox(width: 8),
                    // View Details
                    _ActionButton(
                      label: l10n.viewDetails,
                      icon: Icons.arrow_forward_rounded,
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        final s = (ad['status'] ?? '').toString().toLowerCase();
                        if (s == 'assigned') {
                          final assignedJobId = ad['assignedJobId']?.toString();
                          if (assignedJobId != null &&
                              assignedJobId.isNotEmpty) {
                            Navigator.pushNamed(
                              context,
                              '/job-poster-accepted-details',
                              arguments: {
                                'jobId': adId,
                                'requestId': assignedJobId,
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.adDetailsMissing),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          Navigator.pushNamed(
                            context,
                            '/job-poster-job-detail',
                            arguments: {'jobId': adId, 'requestId': adId},
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: outlined ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
