import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF07111F), Color(0xFF0F172A), Color(0xFF08211E)]
              : const [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFF0FDFA)],
        ),
      ),
      child: child,
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 28});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? const Color(0xDD0F1A2B) : const Color(0xEEFFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: scheme.outlineVariant.withOpacity(dark ? .22 : .55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? .24 : .06),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ProHeader extends StatelessWidget {
  const ProHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [scheme.primary.withOpacity(.34), const Color(0xFF142238), const Color(0xFF0E2A27)]
              : [scheme.primaryContainer, const Color(0xFFE0F2FE), const Color(0xFFCCFBF1)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(dark ? .08 : .55)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(dark ? .10 : .13),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(.88),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(.38)),
              ),
              child: Icon(icon, color: scheme.primary, size: 27),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withOpacity(.72),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 21),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class MetricPill extends StatelessWidget {
  const MetricPill({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 7),
          Text('$label: ', style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 36, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(buttonText!)),
            ],
          ],
        ),
      ),
    );
  }
}

class RequireFamily extends StatelessWidget {
  const RequireFamily({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.family_restroom,
      title: 'Primero crea o elige una familia',
      message: 'Así la app puede separar chat, compra, tareas, menús y calendario de cada familia.',
      buttonText: 'Gestionar familias',
      onPressed: () => context.go('/family-setup'),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.avatarPath,
    this.radius = 18,
  });

  final String initials;
  final String? avatarPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cleanPath = avatarPath?.trim();
    if (cleanPath == null || cleanPath.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primaryContainer,
        child: Text(
          initials.isEmpty ? 'U' : initials,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontSize: radius * .72,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return FutureBuilder<String>(
      future: Supabase.instance.client.storage.from('family-files').createSignedUrl(cleanPath, 3600),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              initials.isEmpty ? 'U' : initials,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: radius * .72,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: scheme.primaryContainer,
          backgroundImage: NetworkImage(url),
        );
      },
    );
  }
}
