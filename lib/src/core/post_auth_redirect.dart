import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Параметри query дар `/profile`: баъди вуруд ба ин масир мегузарем.
const kPostAuthReturnToParam = 'returnTo';

/// Танҳо роутҳои дохили барнома (бе URL-ҳои беруна).
bool isSafeAppReturnPath(String path) {
  final p = path.trim();
  if (p.isEmpty || !p.startsWith('/')) return false;
  if (p.startsWith('//')) return false;
  if (p.contains('://')) return false;
  if (p.contains('..')) return false;
  return true;
}

/// Path + query-и ҷорӣ барои гузоштан ба `returnTo`.
String loginReturnPathFromContext(BuildContext context) {
  final u = GoRouterState.of(context).uri;
  if (!u.hasQuery) return u.path;
  return '${u.path}?${u.query}';
}

/// Масири кабинет: `returnTo` барои баргашт баъди вуруд; `tab` — мисли пештара.
String profilePathForLogin({String? returnTo, String? tab}) {
  final qp = <String, String>{};
  if (returnTo != null && returnTo.isNotEmpty && isSafeAppReturnPath(returnTo)) {
    qp[kPostAuthReturnToParam] = returnTo;
  }
  if (tab != null && tab.isNotEmpty) {
    qp['tab'] = tab;
  }
  if (qp.isEmpty) return '/profile';
  return Uri(path: '/profile', queryParameters: qp).toString();
}
