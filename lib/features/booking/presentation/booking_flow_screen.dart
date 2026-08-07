Created At: 2026-07-11T17:10:28Z
Completed At: 2026-07-11T17:10:28Z
File Path: `file:///H:/nesty/lib/features/booking/presentation/booking_flow_screen.dart`
Total Lines: 1083
Total Bytes: 46600
Showing lines 1 to 800
The following code has been modified to include a line number before every line, in the format: <line_number>: <original_line>. Please note that any changes targeting the original code should remove the line number, colon, and leading space.
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/domain/property.dart';
import '../../trips/domain/booking.dart';
import '../providers/bookings_provider.dart';
import '../../../shared/widgets/nesty_image.dart';
class BookingFlowScreen extends ConsumerStatefulWidget {
  final Property property;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  const BookingFlowScreen({
    super.key,
    required this.property,
    this.initialStartDate,
    this.initialEndDate,
  });
  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}
class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _currentStep = 1;
  DateTime? _startDate;
  DateTime? _endDate;
  int _adults = 1;
  int _children = 0;
  String? _paymentMethod = 'EasyPaisa';
  final TextEditingController _phoneController = TextEditingController();
  String? _bookingId;
  bool _isSavingBooking = false;
  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    if (_startDate != null && _endDate != null) {
      _currentStep = 2; // Start at Guest Selection if dates already picked
    }
  }
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
  Future<void> _saveBookingAndContinue() async {
    setState(() => _isSavingBooking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("You must be logged in to book / بکنگ کے لیے لاگ ان ہونا ضروری ہے");
      }
      final nights = _endDate!.difference(_startDate!).inDays;
      final basePrice = widget.property.price * nights;
      final serviceFee = (basePrice * 0.10).round();
      final tax = (basePrice * 0.16).round();
      const cleaningFee = 1500;
      final total = basePrice + serviceFee + tax + cleaningFee;
      final booking = Booking(
        id: '',
        property: widget.property,
        checkInDate: _startDate!,
        checkOutDate: _endDate!,
        totalPrice: total.toDouble(),
        status: BookingStatus.pending,
        totalGuests: _adults + _children,
        guestId: user.uid,
        guestName: user.displayName ?? 'Guest',
        guestAvatar: user.photoURL ?? 'https://i.pravatar.cc/150?u=${user.uid}',
        hostId: widget.property.hostId ?? 'mock_host_id',
        paymentMethod: _paymentMethod,
        paymentPhone: _phoneController.text.trim(),
        createdAt: DateTime.now(),
      );
      final generatedId = await ref.read(bookingsServiceProvider).createBooking(booking);
      setState(() {
        _bookingId = generatedId;
        _currentStep = 4;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingBooking = false);
    }
  }
  void _nextStep() {
    setState(() {
      if (_currentStep < 4) _currentStep++;
    });
  }
  void _prevStep() {
    setState(() {
      if (_currentStep > 1) _currentStep--;
      else context.pop();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: _buildCurrentStepView(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    String title = '';
    switch (_currentStep) {
      case 1: title = 'Select Dates / تاریخیں منتخب کریں'; break;
      case 2: title = 'Guests / مہمانوں کی تعداد'; break;
      case 3: title = 'Payment & Review / ادائیگی اور جائزہ'; break;
      case 4: title = 'Confirmed / تصدیق ہو گئی'; break;
    }
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
        onPressed: _prevStep,
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }
  Widget _buildStepIndicator() {
    if (_currentStep == 4) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final stepNum = index + 1;
          final isActive = stepNum <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNum',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: stepNum < _currentStep ? AppTheme.primaryColor : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 1: return _buildStep1Dates();
      case 2: return _buildStep2Guests();
      case 3: return _buildStep3Payment();
      case 4: return _buildStep4Success();
      default: return const SizedBox.shrink();
    }
  }
  Widget _buildStep1Dates() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.calendar_month_rounded, size: 80, color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        const SizedBox(height: 24),
        Text(
          'When are you staying?',
          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ElevatedButton(
            onPressed: () => _selectDateRange(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 2),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.date_range_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 16),
                Text(
                  _startDate == null 
                    ? 'Pick Start & End Dates' 
                    : '${DateFormat('MMM d').format(_startDate!)} – ${DateFormat('MMM d').format(_endDate!)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
  Widget _buildStep2Guests() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who\'s coming?',
            style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'This place has a maximum of 4 guests.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 32),
          _buildGuestCounter('Adults', 'Ages 13+', _adults, (v) => setState(() => _adults = v)),
          const Divider(height: 48),
          _buildGuestCounter('Children', 'Ages 2–12', _children, (v) => setState(() => _children = v)),
          const Divider(height: 48),
          _buildGuestCounter('Infants', 'Under 2 • Not counted in guest limit', _infants, (v) => setState(() => _infants = v)),
        ],
      ),
    );
  }
  Widget _buildGuestCounter(String title, String subtitle, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoundButton(Icons.remove, value > 0 ? () => onChanged(value - 1) : null),
            const SizedBox(width: 16),
            SizedBox(
              width: 20,
              child: Center(
                child: Text('$value', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 16),
            _buildRoundButton(Icons.add, value < 4 ? () => onChanged(value + 1) : null),
          ],
        ),
      ],
    );
  }
  Widget _buildRoundButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: onTap == null ? Colors.grey.shade300 : Colors.black54),
        ),
        child: Icon(icon, size: 20, color: onTap == null ? Colors.grey.shade300 : Colors.black54),
      ),
    );
  }
  Widget _buildStep3Payment() {
    final nights = _endDate!.difference(_startDate!).inDays;
    final basePrice = widget.property.price * nights;
    final serviceFee = (basePrice * 0.10).round(); // 10% from analysis
    final tax = (basePrice * 0.16).round(); // 16% from analysis
    const cleaningFee = 1500;
    final total = basePrice + serviceFee + tax + cleaningFee;
    final format = NumberFormat("#,##0", "en_US");
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Property Summary
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: NestyImage(src: widget.property.imageUrl, width: 100, height: 100, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.property.title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(widget.property.location, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 48),
          // 2. Price Breakdown
          Text('Price Details / قیمت کی تفصیل', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          _buildPriceRow('PKR ${format.format(widget.property.price)} x $nights nights', 'PKR ${format.format(basePrice)}'),
          _buildPriceRow('Cleaning fee', 'PKR ${format.format(cleaningFee)}'),
          _buildPriceRow('Service fee (10%)', 'PKR ${format.format(serviceFee)}'),
          _buildPriceRow('Taxes & Fees (16%)', 'PKR ${format.format(tax)}'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total / کل', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900)),
              Text('PKR ${format.format(total)}', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, size: 14, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✓ No extra charges after this / اس کے بعد کوئی اضافی چارجز نہیں۔',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const Divider(height: 48),
          // 3. Message to Host
          Text('Message the host (optional)', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share a bit about your trip...',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
          const SizedBox(height: 32),
          // 4. Payment Method Selection (Redesigned)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Payment Method', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Select a secure payment method / محفوظ ادائیگی کا طریقہ منتخب کریں', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                _buildPaymentOption('EasyPaisa', 'ایزی پیسہ', Icons.phone_android_rounded, true),
                const SizedBox(height: 16),
                _buildPaymentOption('JazzCash', 'جاز کیش', Icons.phone_android_rounded, true),
                const SizedBox(height: 16),
                _buildPaymentOption('Debit/Credit Card', 'ڈیبٹ/کریڈٹ کارڈ', Icons.credit_card_rounded, false),
                const SizedBox(height: 16),
                // Details Section (Moved Inside)
                if (_paymentMethod != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_paymentMethod Details', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
                      const SizedBox(height: 16),
                      Text(_paymentMethod == 'Debit/Credit Card' ? 'Card Number' : 'Mobile Number', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_paymentMethod != 'Debit/Credit Card') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text('+92', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: _paymentMethod == 'Debit/Credit Card' ? TextInputType.number : TextInputType.phone,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  hintText: _paymentMethod == 'Debit/Credit Card' ? 'XXXX XXXX XXXX XXXX' : '3XX XXXXXXX',
                                  hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.primaryColor)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () {}, // Optional action
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade200),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Send OTP (Optional)', style: GoogleFonts.plusJakartaSans(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'OTP verification is optional for testing',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Secure payment • 256-bit SSL encryption', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 48),
          // 5. Ground Rules
          Text('Ground rules / بنیادی اصول', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          _buildRuleRow(Icons.rule_folder_rounded, 'Follow the house rules'),
          _buildRuleRow(Icons.house_siding_rounded, 'Treat your host\'s home like your own'),
          const SizedBox(height: 24),
          // 6. Cancellation (Summary)
          const Divider(height: 32),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(child: Text('Free cancellation for 48 hours.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.blue))),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  Widget _buildRuleRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 16),
          Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w700)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
  Widget _buildPaymentOption(String title, String urduTitle, IconData icon, bool mostPopular) {
    final isSelected = _paymentMethod == title;
    return GestureDetector(
      onTap: () {
        setState(() => _paymentMethod = title);
        _phoneController.clear(); // Clear input when changing method
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.black87, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(urduTitle, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w700)),
                  if (mostPopular) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Most Popular', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400, width: isSelected ? 2 : 1),
              ),
              child: isSelected 
                  ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryColor)))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStep4Success() {
    final nights = _endDate!.difference(_startDate!).inDays;
    final basePrice = widget.property.price * nights;
    final serviceFee = (basePrice * 0.10).round();
    final tax = (basePrice * 0.16).round();
    const cleaningFee = 1500;
    final total = basePrice + serviceFee + tax + cleaningFee;
    final format = NumberFormat("#,##0", "en_US");
    final dateFormat = DateFormat('MMM d, yyyy');
    final String bookingId = _bookingId ?? '#N/A';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // If you want a small success indicator at top
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          // 1. Booking Details Card
          Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking Details / بکنگ کی تفصیلات', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),
                      _buildDetailRow('Booking ID', bookingId, isBoldRight: true),
                      _buildDetailRow('Property', widget.property.title, isBoldRight: true),
                      _buildDetailRow('Location', widget.property.location, isBoldRight: true),
                      _buildDetailRow('Check in', dateFormat.format(_startDate!), isBoldRight: true),
                      _buildDetailRow('Check out', dateFormat.format(_endDate!), isBoldRight: true),
                      _buildDetailRow('Guests', '${_adults + _children} guest${_adults + _children > 1 ? 's' : ''}', isBoldRight: true),
                      _buildDetailRow('Nights', nights.toString(), isBoldRight: true),
                      _buildDetailRow('Payment Method', _paymentMethod ?? 'N/A', isBoldRight: true),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Status', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7), // Light yellow
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Pending Approval',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFB45309), fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.grey.shade300),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black)),
                      Text('PKR ${format.format(total)}', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 2. What's Next Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Light blue-grey background per image
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('What\'s Next?', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF334155))),
                  ],
                ),
                const SizedBox(height: 20),
                _buildNextStepRowNew(1, 'The host will review your booking request'),
                const SizedBox(height: 16),
                _buildNextStepRowNew(2, 'You\'ll receive a notification once the host accepts'),
                const SizedBox(height: 16),
                _buildNextStepRowNew(3, 'After approval, you can message the host and get check-in details'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 3. Action Buttons
          ElevatedButton(
            onPressed: () => context.go('/trips'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('View My Bookings', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showReceiptDialog(context, bookingId, dateFormat.format(_startDate!), dateFormat.format(_endDate!), nights, total),
The above content does NOT show the entire file contents. If you need to view any lines of the file which were not shown to complete your task, call this tool again to view those lines.
