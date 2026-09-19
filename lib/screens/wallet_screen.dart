import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/borrower_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/borrower_repository.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final BorrowerRepository _repo = BorrowerRepository();
  BorrowerModel? _borrower;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoading = true);
    final user = AuthRepository.currentUser;
    if (user != null && user.id != null) {
      _borrower = await _repo.getByUserId(user.id!);
      
      // Create if it doesn't exist
      if (_borrower == null && !user.isStaff) {
        final newBorrower = BorrowerModel(
          userId: user.id!,
          membershipDate: DateTime.now().toIso8601String(),
          balance: 0.0,
        );
        final id = await _repo.insert(newBorrower);
        _borrower = await _repo.getById(id);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _topUpBalance() async {
    final amountController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إيداع رصيد', style: TextStyle(color: AppColors.primaryNavy)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('أدخل المبلغ المراد إيداعه (عملية وهمية للتجربة):'),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0 && _borrower != null) {
                  _borrower!.balance += amount;
                  await _repo.update(_borrower!);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إيداع الرصيد بنجاح!'), backgroundColor: Colors.green),
                    );
                    _loadWallet();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('إيداع', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_borrower == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المحفظة'), backgroundColor: AppColors.primaryNavy),
        body: const Center(child: Text('هذه الشاشة مخصصة للطلاب فقط')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفظة الإلكترونية'),
        backgroundColor: AppColors.primaryNavy,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryNavy, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 60, color: Colors.white),
                    const SizedBox(height: 15),
                    const Text('رصيدك الحالي', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(
                      '${_borrower!.balance.toStringAsFixed(2)} ريال',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: AppColors.accentGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _topUpBalance,
                  icon: const Icon(Icons.add_card, color: Colors.white),
                  label: const Text('إيداع رصيد', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'يمكنك استخدام رصيدك لسداد أي غرامات تأخير مترتبة عليك مباشرة من التطبيق.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
