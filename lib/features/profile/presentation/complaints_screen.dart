import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';

class ComplaintsScreen extends ConsumerStatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  String _selectedCategory = 'Property Condition';
  String? _selectedBookingId;
  String? _selectedComplaineeId;
  String? _selectedComplaineeName;
  String? _selectedPropertyTitle;
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Property Condition',
    'Host Behavior',
    'Guest Behavior',
    'Rules Violation',
    'Financial Dispute',
    'Technical Issue',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String currentUserId = user?.uid ?? 'mock_user';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Complaints Manager',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: AppTheme.primaryColor,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Filed by Me'),
            Tab(text: 'Received Against Me'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComplaintsList(currentUserId, isComplainant: true),
          _buildComplaintsList(currentUserId, isComplainant: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewComplaintSheet(context, currentUserId),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_moderator_rounded, size: 20),
        label: Text(
          'File Complaint',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintsList(String userId, {required bool isComplainant}) {
    final queryField = isComplainant ? 'complainantId' : 'complaineeId';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where(queryField, isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isComplainant ? Icons.sentiment_satisfied_alt_rounded : Icons.shield_rounded,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isComplainant ? 'All clear!' : 'No complaints against you',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isComplainant
                        ? 'If you have any issues with a stay, host, or guest, file a complaint using the button below.'
                        : 'Awesome! You have kept a perfect record with your fellow travelers.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Sort locally by date descending
        final sortedDocs = docs.toList()
          ..sort((a, b) {
            final aTime = a.data()['createdAt'] as Timestamp?;
            final bTime = b.data()['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final complaint = sortedDocs[index].data();
            final String docId = sortedDocs[index].id;
            return _buildComplaintCard(docId, complaint, isComplainant);
          },
        );
      },
    );
  }

  Widget _buildComplaintCard(String docId, Map<String, dynamic> data, bool isComplainant) {
    final String category = data['category'] ?? 'Complaint';
    final String description = data['description'] ?? '';
    final String status = data['status'] ?? 'pending';
    final Timestamp? timestamp = data['createdAt'] as Timestamp?;
    final String propertyTitle = data['propertyTitle'] ?? '';
    final String partyName = isComplainant
        ? (data['complaineeName'] ?? 'Other Party')
        : (data['complainantName'] ?? 'Anonymous Guest');

    final String formattedDate = timestamp != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate())
        : 'Date unknown';

    Color statusColor;
    Color statusBg;
    String statusText;

    switch (status.toLowerCase()) {
      case 'resolved':
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFFD1E7DD);
        statusText = 'Resolved';
        break;
      case 'under review':
      case 'investigating':
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFFF3CD);
        statusText = 'Under Review';
        break;
      default:
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0xFFF8D7DA);
        statusText = 'Pending';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showComplaintDetails(context, docId, data, isComplainant),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                category,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              if (propertyTitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.business_rounded, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        propertyTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(
                    isComplainant ? 'Reported: $partyName' : 'Reported By: $partyName',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComplaintDetails(
      BuildContext context, String docId, Map<String, dynamic> data, bool isComplainant) {
    final String category = data['category'] ?? 'Complaint';
    final String description = data['description'] ?? '';
    final String status = data['status'] ?? 'pending';
    final String propertyTitle = data['propertyTitle'] ?? '';
    final String complainantName = data['complainantName'] ?? 'Anonymous';
    final String complaineeName = data['complaineeName'] ?? 'Host/Guest';
    final Timestamp? timestamp = data['createdAt'] as Timestamp?;
    final String formattedDate = timestamp != null
        ? DateFormat('MMMM d, yyyy • h:mm a').format(timestamp.toDate())
        : 'Unknown';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.description_outlined, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(
                'Complaint Details',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                _detailItem('Status', status.toUpperCase()),
                _detailItem('Date Filed', formattedDate),
                _detailItem('Category', category),
                if (propertyTitle.isNotEmpty) _detailItem('Property', propertyTitle),
                _detailItem('Complainant', complainantName),
                _detailItem('Reported Person', complaineeName),
                const SizedBox(height: 16),
                Text(
                  'Description:',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, height: 1.5, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewComplaintSheet(BuildContext context, String currentUserId) {
    // Reset selection state variables
    _selectedCategory = 'Property Condition';
    _selectedBookingId = null;
    _selectedComplaineeId = null;
    _selectedComplaineeName = null;
    _selectedPropertyTitle = null;
    _descriptionController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(stContext).viewInsets.bottom + 24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'File a Complaint',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(stContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Category',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Select Related Booking',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Fetch all user bookings to link complaint
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('bookings')
                            .snapshots(),
                        builder: (bkContext, bkSnapshot) {
                          if (!bkSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                          }
                          
                          // Filter bookings where user is guest or host
                          final bookings = bkSnapshot.data!.docs.where((doc) {
                            final data = doc.data();
                            return data['guestId'] == currentUserId || data['hostId'] == currentUserId;
                          }).toList();

                          if (bookings.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                'No bookings found to link. You can still submit a general complaint below.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value: _selectedBookingId,
                            hint: Text('Choose a booking stay', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            items: bookings.map((b) {
                              final data = b.data();
                              final String propertyTitle = data['propertyTitle'] ?? 'Property';
                              final String guestName = data['guestName'] ?? 'Guest';
                              final String hostName = data['hostName'] ?? 'Host';
                              final bool isCurrentUserHost = data['hostId'] == currentUserId;
                              final String otherParty = isCurrentUserHost ? guestName : hostName;
                              final String displayText = '$propertyTitle (with $otherParty)';

                              return DropdownMenuItem(
                                value: b.id,
                                child: Text(
                                  displayText,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final selectedDoc = bookings.firstWhere((b) => b.id == val);
                                final data = selectedDoc.data();
                                final bool isCurrentUserHost = data['hostId'] == currentUserId;

                                setSheetState(() {
                                  _selectedBookingId = val;
                                  _selectedPropertyTitle = data['propertyTitle'] ?? 'Property';
                                  _selectedComplaineeId = isCurrentUserHost ? data['guestId'] : data['hostId'];
                                  _selectedComplaineeName = isCurrentUserHost ? data['guestName'] : data['hostName'];
                                });
                              }
                            },
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      Text(
                        'Details / Description',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Please describe the incident or issue in detail...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // Build complaint data
                              final authState = ref.read(authProvider);
                              final complainantName = authState.name ?? 'Muhammad Haad';
                              
                              final complaintData = {
                                'complainantId': currentUserId,
                                'complainantName': complainantName,
                                'complaineeId': _selectedComplaineeId ?? 'system_admin',
                                'complaineeName': _selectedComplaineeName ?? 'Nesty Support',
                                'bookingId': _selectedBookingId ?? '',
                                'propertyTitle': _selectedPropertyTitle ?? 'General Support',
                                'category': _selectedCategory,
                                'description': _descriptionController.text.trim(),
                                'status': 'pending',
                                'createdAt': FieldValue.serverTimestamp(),
                              };

                              try {
                                await FirebaseFirestore.instance
                                    .collection('complaints')
                                    .add(complaintData);

                                Navigator.pop(stContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Complaint submitted successfully!',
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to submit complaint: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Submit Complaint',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
