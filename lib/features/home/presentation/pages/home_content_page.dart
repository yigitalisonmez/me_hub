import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../features/quote/presentation/widgets/daily_quote_widget.dart';
import '../../../../features/todo/presentation/widgets/todo_header_widget.dart';
import '../../../../features/todo/presentation/widgets/todo_card_widget.dart';

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const TodoHeaderWidget(),
            const SizedBox(height: 24),
            const DailyQuoteWidget(),
            const SizedBox(height: 20),
            const TodoCardWidget(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
