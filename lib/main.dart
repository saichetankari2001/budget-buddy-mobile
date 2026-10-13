import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/expenses/expenses_screen.dart';
import 'features/coach/coach_screen.dart';
import 'features/coach/coach_providers.dart';

void main() {
  runApp(const ProviderScope(child: BudgetBuddyApp()));
}

class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Buddy',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const _RootGate(),
    );
  }
}

class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    ref.listen<AsyncValue<AuthResult>>(authStateProvider, (previous, next) {
      final was = previous?.valueOrNull?.isAuthenticated;
      final now = next.valueOrNull?.isAuthenticated;
      // Only act when the authenticated/unauthenticated state actually flips — not on every
      // rebuild (e.g. the AsyncLoading() a login attempt sets doesn't count; `was`/`now` stay
      // null-free only once a real before/after value exists on both sides).
      if (was != null && now != null && was != now) {
        // Pop any screen pushed on top of this route (e.g. SignupScreen pushed from LoginScreen)
        // so the swapped root content underneath (LoginScreen <-> the tab shell) becomes visible.
        Navigator.of(context).popUntil((route) => route.isFirst);
        // Chat history belongs to whichever account was logged in — never let it survive a
        // login/logout transition into a different session.
        ref.invalidate(coachMessagesProvider);
      }
    });

    return authState.when(
      // A login/signup attempt sets AsyncLoading() on an already-initialized provider — that's a
      // reload, not the app's first load. Without this, _RootGate would swap to the full-screen
      // spinner on every attempt, destroying whatever screen was showing (losing typed text).
      skipLoadingOnReload: true,
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginScreen(),
      data: (result) => result.isAuthenticated ? const _MainTabs() : const LoginScreen(),
    );
  }
}

class _MainTabs extends StatefulWidget {
  const _MainTabs();

  @override
  State<_MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<_MainTabs> {
  int _index = 0;

  static const _screens = [DashboardScreen(), ExpensesScreen(), CoachScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Coach'),
        ],
      ),
    );
  }
}
