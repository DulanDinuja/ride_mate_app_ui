import 'package:flutter/material.dart';

import '../models/saved_card.dart';
import '../services/payment_service.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/custom_button.dart';
import 'add_card_screen.dart';

/// Displays the user's saved payment cards and allows adding a new card
/// via PayHere preapproval (tokenization).
///
/// Maps to: GET /payment/saved-cards/{userId}
class PaymentMethodsScreen extends StatefulWidget {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  const PaymentMethodsScreen({
    super.key,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<SavedCard> _cards = [];
  bool _isLoading = true;
  int? _selectedCardId; // tracks which card shows the delete overlay

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _selectedCardId = null;
    });
    try {
      final cards = await PaymentService.getSavedCards(widget.userId);
      // Extra client-side safety: only show active cards
      _cards = cards.where((c) => c.isActive == 'YES').toList();
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addCard() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddCardScreen(
          userId: widget.userId,
          firstName: widget.firstName,
          lastName: widget.lastName,
          email: widget.email,
          phone: widget.phone,
        ),
      ),
    );

    if (result == true && mounted) {
      SnackBarHelper.showSuccess(context, 'Card added successfully');
      _loadCards();
    }
  }

  /// Called when a card tile is tapped.
  /// First tap → select (shows delete icon overlay).
  /// Tap on already-selected card → deselect.
  void _onCardTap(SavedCard card) {
    setState(() {
      _selectedCardId = (_selectedCardId == card.id) ? null : card.id;
    });
  }

  /// Confirms and executes soft-delete (isActive = NO) for the given card.
  Future<void> _deleteCard(SavedCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Card'),
        content: Text(
          'Remove ${card.cardNoMasked ?? 'this card'}?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await PaymentService.deleteCard(
        cardId: card.id!,
        userId: widget.userId,
      );
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Card removed successfully');
        _loadCards();
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.toString());
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  /// Returns the asset path for the card background image.
  /// MASTER → card_master.png, VISA → card_visa.png, others → null.
  String? _getCardAsset(SavedCard card) {
    switch (card.paymentMethod?.toUpperCase()) {
      case 'MASTER':
        return 'assets/images/card_master.png';
      case 'VISA':
        return 'assets/images/card_visa.png';
      default:
        return null;
    }
  }

  /// Returns the native aspect ratio (width / height) of the card template.
  /// MASTER → 1404/892, VISA → 1400/887.
  double _getCardAspectRatio(SavedCard card) {
    switch (card.paymentMethod?.toUpperCase()) {
      case 'MASTER':
        return 1404 / 892;
      case 'VISA':
        return 1400 / 887;
      default:
        return 1404 / 892; // sensible default
    }
  }

  Color _getCardColor(SavedCard card) {
    switch (card.paymentMethod?.toUpperCase()) {
      case 'VISA':
        return const Color(0xFF1A1F71);
      case 'MASTER':
        return const Color(0xFFEB001B);
      default:
        return const Color(0xFF040F1B);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: Column(
        children: [
          // ── Card list / loading / empty ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadCards,
                    child: _cards.isEmpty
                        ? _buildEmptyState()
                        : _buildCardList(),
                  ),
          ),

          // ── Bottom "Add Card" button — same style as all other screens ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              child: CustomButton(
                text: 'Add Card',
                onPressed: _addCard,
                backgroundColor: const Color(0xFF169F7E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Icon(Icons.credit_card_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No saved cards',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a card to make payments easier',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return _buildCardTile(card);
      },
    );
  }

  // ─── Card tile with tap-to-select delete overlay ─────────────────

  Widget _buildCardTile(SavedCard card) {
    final isSelected = _selectedCardId == card.id;
    final assetPath = _getCardAsset(card);

    final cardWidget = assetPath != null
        ? _buildImageCard(card, assetPath)
        : _buildFallbackCardTile(card);

    return GestureDetector(
      onTap: () => _onCardTap(card),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            cardWidget,

            // ── Delete overlay (shown when card is selected) ──────
            if (isSelected)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: Colors.black.withOpacity(0.55),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _deleteCard(card),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.85),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(SavedCard card, String assetPath) {
    final aspectRatio = _getCardAspectRatio(card);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            final hPad = w * 0.065;
            final vPad = h * 0.108;
            final cardNumTop = h * 0.42;
            final badgeTop = h * 0.054;
            final badgeRight = w * 0.034;
            final cornerRadius = w * 0.053;

            return ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(assetPath, fit: BoxFit.cover),

                  Positioned(
                    left: hPad,
                    right: hPad,
                    top: cardNumTop,
                    child: Text(
                      card.cardNoMasked ?? '•••• •••• •••• ••••',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.5,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    left: hPad,
                    bottom: vPad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Card Holder Name',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          (card.cardHolderName ?? 'N/A').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    right: hPad,
                    bottom: vPad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Expiry Date',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          card.cardExpiry ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (card.active)
                    Positioned(
                      top: badgeTop,
                      right: badgeRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.greenAccent.withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Fallback gradient card for unknown card types (no template image).
  Widget _buildFallbackCardTile(SavedCard card) {
    final cardColor = _getCardColor(card);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardColor, cardColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.paymentMethod ?? 'CARD',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              card.cardNoMasked ?? '•••• •••• •••• ••••',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARD HOLDER',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.cardHolderName ?? 'N/A',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'EXPIRES',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.cardExpiry ?? 'N/A',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            if (card.active)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

