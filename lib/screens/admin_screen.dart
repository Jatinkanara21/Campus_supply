import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  static const forest = Color(0xFF0B2E20), dark = Color(0xFF124D36), emerald = Color(0xFF1F7A5A), mint = Color(0xFFA7D7C5), gold = Color(0xFFD8B76A), taupe = Color(0xFF8A7B68), sage = Color(0xFF5F8F7A), espresso = Color(0xFF2A211B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: forest,
      appBar: AppBar(title: const Text('Admin Dashboard'), leading: const Icon(Icons.admin_panel_settings_rounded), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded))]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Welcome back, Admin!', style: TextStyle(color: mint, fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 5), const Text('Manage your Campus Supply store.', style: TextStyle(color: taupe)), const SizedBox(height: 20),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.55, children: [_metric('145', 'Products', Icons.inventory_2_outlined), _metric('78', 'Orders', Icons.receipt_long_outlined), _metric('1,256', 'Users', Icons.people_outline_rounded), _metric('₹1.25L', 'Revenue', Icons.currency_rupee_rounded)]),
        const SizedBox(height: 22),
        _title('Quick Actions'),
        Row(children: [_action(Icons.add_box_outlined, 'Add Product'), _action(Icons.category_outlined, 'Categories'), _action(Icons.people_outline_rounded, 'Users')]),
        const SizedBox(height: 22),
        _title('Recent Products'),
        ...['Campus Pro Backpack', 'Wireless Headphones', 'Premium Notebook', 'Steel Water Bottle'].map((name) => Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(17)), child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFF356B4A), child: Icon(Icons.inventory_2_outlined, color: mint)), title: Text(name, style: const TextStyle(color: mint, fontWeight: FontWeight.w700)), subtitle: const Text('Active • In stock', style: TextStyle(color: sage, fontSize: 11)), trailing: const Icon(Icons.edit_outlined, color: gold)))),
        const SizedBox(height: 12),
        _title('Sales Overview'),
        Container(height: 170, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: espresso, borderRadius: BorderRadius.circular(22), border: Border.all(color: sage.withValues(alpha: .45))), child: CustomPaint(painter: _ChartPainter(), child: const SizedBox.expand())),
      ]),
    );
  }

  Widget _metric(String value, String label, IconData icon) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(20), border: Border.all(color: sage.withValues(alpha: .35))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: gold), const SizedBox(height: 8), Text(value, style: const TextStyle(color: mint, fontSize: 21, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: sage, fontSize: 10))]));
  Widget _title(String text) => Padding(padding: const EdgeInsets.only(bottom: 11), child: Text(text, style: const TextStyle(color: mint, fontSize: 18, fontWeight: FontWeight.w800)));
  Widget _action(IconData icon, String text) => Expanded(child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 15), decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(17)), child: Column(children: [Icon(icon, color: gold), const SizedBox(height: 6), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: mint, fontSize: 10, fontWeight: FontWeight.w700))])));
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFF5F8F7A).withValues(alpha: .2)..strokeWidth = 1;
    final line = Paint()..color = const Color(0xFFA7D7C5)..strokeWidth = 3..style = PaintingStyle.stroke;
    for (var i = 1; i < 5; i++) { final y = size.height * i / 5; canvas.drawLine(Offset(0, y), Offset(size.width, y), grid); }
    final points = [0.78, .58, .66, .40, .48, .25, .18];
    final path = Path();
    for (var i = 0; i < points.length; i++) { final p = Offset(size.width * i / (points.length - 1), size.height * points[i]); if (i == 0) path.moveTo(p.dx, p.dy); else path.lineTo(p.dx, p.dy); }
    canvas.drawPath(path, line);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
