import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../utils/game_state.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _keyController = TextEditingController();
  bool _isActivating = false;
  String _errorMsg = '';
  String _successMsg = '';
  late String _paymentRef;

  // ── OWNER CONFIG ── Change these before publishing ──
  static const String ownerWhatsApp = '919849194886'; // Your WhatsApp number with country code
  static const String ownerName = 'MindPuzzles India';
  static const double subscriptionPrice = 99.0; // Price in INR
  static const String upiId = 'n.karthik90@okicici'; // Your UPI ID
  // ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _paymentRef = GameState.generatePaymentReference();
  }

  Future<void> _openWhatsApp() async {
    final message = Uri.encodeComponent(
      '🎮 MindPuzzles India - Subscription Request\n\n'
      '📋 Payment Reference: $_paymentRef\n'
      '💰 Amount: ₹$subscriptionPrice\n'
      '🔢 UPI ID: $upiId\n\n'
      'Hi! I\'d like to purchase a subscription for MindPuzzles India. '
      'Please find my payment reference above. '
      'I will send payment to your UPI ID and share screenshot.'
    );
    final url = Uri.parse('https://wa.me/$ownerWhatsApp?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Please install WhatsApp.')),
        );
      }
    }
  }

  Future<void> _activateKey() async {
    final key = _keyController.text.trim().toUpperCase();
    if (key.isEmpty) {
      setState(() => _errorMsg = 'Please enter the activation key');
      return;
    }
    setState(() { _isActivating = true; _errorMsg = ''; _successMsg = ''; });
    await Future.delayed(const Duration(milliseconds: 800));
    final success = await GameState.activateSubscription(key);
    setState(() {
      _isActivating = false;
      if (success) {
        _successMsg = '🎉 Subscription activated! Enjoy unlimited puzzles!';
      } else {
        _errorMsg = 'Invalid key. Please contact the owner via WhatsApp.';
      }
    });
    if (success && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.popUntil(context, ModalRoute.withName('/'));
    }
  }

  void _copyRef() {
    Clipboard.setData(ClipboardData(text: _paymentRef));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reference copied!'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (GameState.isSubscribed()) return _buildAlreadySubscribed();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Unlock All Levels', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppTheme.gold)),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildHeroCard(),
          const SizedBox(height: 20),
          _buildBenefits(),
          const SizedBox(height: 20),
          _buildPaymentSteps(),
          const SizedBox(height: 20),
          _buildKeyActivation(),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFF6F00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFFFFB300).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        const Text('👑', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 12),
        Text('Unlock All Puzzles', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('One-time payment • Lifetime access', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
          child: Text('₹${subscriptionPrice.toStringAsFixed(0)} only', style: GoogleFonts.poppins(color: const Color(0xFFFF6F00), fontSize: 20, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _buildBenefits() {
    final benefits = [
      ('🔢', 'Unlimited Sudoku', 'Easy, Medium & Hard — infinite levels'),
      ('🟦', 'Unlimited Patches', 'New random puzzles every session'),
      ('🔗', 'Unlimited Zip', 'Endless path puzzles to solve'),
      ('♾️', 'Lifetime Access', 'Pay once, play forever'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('What You Get', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...benefits.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Text(b.$1, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.$2, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(b.$3, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
            ])),
            const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
          ]),
        )),
      ]),
    );
  }

  Widget _buildPaymentSteps() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How to Subscribe', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        _step('1', 'Note your Payment Reference', null),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 4, 0, 12),
          child: GestureDetector(
            onTap: _copyRef,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.primary.withOpacity(0.2))),
              child: Row(children: [
                Text(_paymentRef, style: GoogleFonts.sourceCodePro(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 2)),
                const Spacer(),
                const Icon(Icons.copy, size: 16, color: AppTheme.primary),
              ]),
            ),
          ),
        ),
        _step('2', 'Send ₹${subscriptionPrice.toStringAsFixed(0)} to UPI: $upiId', null),
        const SizedBox(height: 8),
        _step('3', 'Contact owner on WhatsApp with payment screenshot', null),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openWhatsApp,
            icon: const Text('💬', style: TextStyle(fontSize: 18)),
            label: Text('Contact on WhatsApp', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _step('4', 'Owner verifies payment and sends you an activation key', null),
      ]),
    );
  }

  Widget _step(String num, String text, Widget? child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24, height: 24,
          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
          child: Center(child: Text(num, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black87, height: 1.5))),
      ]),
    );
  }

  Widget _buildKeyActivation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Enter Activation Key', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Enter the key sent by the owner via WhatsApp', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 14),
        TextField(
          controller: _keyController,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.sourceCodePro(fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'e.g. ABCD1234',
            hintStyle: GoogleFonts.sourceCodePro(color: Colors.grey[400]),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
            prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppTheme.primary),
          ),
        ),
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_errorMsg, style: GoogleFonts.poppins(color: AppTheme.error, fontSize: 12)),
        ],
        if (_successMsg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_successMsg, style: GoogleFonts.poppins(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isActivating ? null : _activateKey,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isActivating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Activate Key 🔓', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  Widget _buildAlreadySubscribed() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Subscription', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
      ),
      body: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('👑', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('You\'re a PRO!', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.gold)),
          const SizedBox(height: 8),
          Text('Enjoy unlimited access to all puzzles', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
            child: Text('Play Now!', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ]),
      )),
    );
  }

  @override
  void dispose() { _keyController.dispose(); super.dispose(); }
}
