import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class AdCard extends StatelessWidget {
  final String adId;
  final Map<String, dynamic> ad;
  const AdCard({required this.adId, required this.ad, Key? key})
    : super(key: key);

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final postDate = DateTime(date.year, date.month, date.day);

    if (postDate == today) {
      return l10n.postedToday;
    } else if (postDate == yesterday) {
      return l10n.postedYesterday;
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
    final bool isActive = status.toString().toLowerCase() == 'active';

    final theme = Theme.of(context);
    final green = Colors.green;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive ? green.withOpacity(0.15) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getLocalizedStatus(status, l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isActive ? green : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// Description
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            /// Location & Date
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  dateText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.editComingSoon)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: green, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      l10n.edit,
                      style: TextStyle(
                        color: green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/job-poster-requests',
                        arguments: {'jobId': adId},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.requests,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final status =
                          (ad['status'] ?? '').toString().toLowerCase();
                      if (status == 'assigned') {
                        final assignedJobId = ad['assignedJobId']?.toString();
                        if (assignedJobId != null && assignedJobId.isNotEmpty) {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.viewDetails,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
