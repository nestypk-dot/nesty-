import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class GuestSelectionScreen extends HookWidget {
  final int initialAdults;
  final int initialChildren;
  final int initialInfants;
  final int initialPets;

  const GuestSelectionScreen({
    super.key,
    this.initialAdults = 1,
    this.initialChildren = 0,
    this.initialInfants = 0,
    this.initialPets = 0,
  });

  @override
  Widget build(BuildContext context) {
    final adults = useState<int>(initialAdults);
    final children = useState<int>(initialChildren);
    final infants = useState<int>(initialInfants);
    final pets = useState<int>(initialPets);

    // Calculate total guests for the bottom bar summary
    final int totalCount = adults.value + children.value + infants.value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                adults.value = 1;
                children.value = 0;
                infants.value = 0;
                pets.value = 0;
              },
              child: Text(
                'Clear all',
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Who\'s coming?',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 40),
            
            _GuestSelectorItem(
              title: 'Adults',
              subtitle: 'Ages 13 or above',
              count: adults.value,
              onMinus: adults.value > 1 ? () => adults.value-- : null,
              onPlus: () => adults.value++,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: Color(0xFFF0F0F0), thickness: 1),
            ),
            
            _GuestSelectorItem(
              title: 'Children',
              subtitle: 'Ages 2–12',
              count: children.value,
              onMinus: children.value > 0 ? () => children.value-- : null,
              onPlus: () => children.value++,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: Color(0xFFF0F0F0), thickness: 1),
            ),
            
            _GuestSelectorItem(
              title: 'Infants',
              subtitle: 'Under 2',
              count: infants.value,
              onMinus: infants.value > 0 ? () => infants.value-- : null,
              onPlus: () => infants.value++,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: Color(0xFFF0F0F0), thickness: 1),
            ),
            
            _GuestSelectorItem(
              title: 'Pets',
              subtitle: 'Bringing a service animal?',
              count: pets.value,
              onMinus: pets.value > 0 ? () => pets.value-- : null,
              onPlus: () => pets.value++,
              isUnderline: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Column: Total Guests
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalCount guest${totalCount == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    if (infants.value > 0 || pets.value > 0)
                      Text(
                        '${infants.value > 0 ? '${infants.value} infant${infants.value > 1 ? 's' : ''}' : ''}${infants.value > 0 && pets.value > 0 ? ', ' : ''}${pets.value > 0 ? '${pets.value} pet${pets.value > 1 ? 's' : ''}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Right Button: Add Guest
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.pop({
                    'adults': adults.value,
                    'children': children.value,
                    'infants': infants.value,
                    'pets': pets.value,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add guest',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestSelectorItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final bool isUnderline;

  const _GuestSelectorItem({
    required this.title,
    required this.subtitle,
    required this.count,
    this.onMinus,
    this.onPlus,
    this.isUnderline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  decoration: isUnderline ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CounterButton(
              icon: Icons.remove,
              onPressed: onMinus,
              isEnabled: onMinus != null,
            ),
            const SizedBox(width: 14),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              alignment: Alignment.center,
              child: Text(
                count.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 14),
            _CounterButton(
              icon: Icons.add,
              onPressed: onPlus,
              isEnabled: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const _CounterButton({
    required this.icon,
    this.onPressed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? () {
        HapticFeedback.lightImpact();
        onPressed!();
      } : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isEnabled ? Colors.grey.shade400 : Colors.grey.shade200,
            width: 1,
          ),
          color: Colors.white,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isEnabled ? Colors.black : Colors.grey.shade300,
        ),
      ),
    );
  }
}
