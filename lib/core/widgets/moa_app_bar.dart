import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:moamoa/core/theme/moa_theme.dart';

/// 상세/입력 화면 상단의 뒤로가기 AppBar (Figma "Top Bar").
///
/// [AppBar] 를 그대로 상속해서 높이(56), 상태 표시줄 처리 등 기본 동작은 AppBar 를 따릅니다.
/// `Scaffold(appBar: MoaAppBar())` 처럼 씁니다. (AppBar 는 const 생성자가 아니라 `const` 를 붙일 수 없습니다.)
/// 오른쪽에 버튼이 필요하면 [actions] 로 넘깁니다.
/// 요청을 보내는 중처럼 화면을 닫으면 안 될 때는 [backEnabled] 를 false 로 넘겨 왼쪽 버튼을 누를 수 없게 합니다.
/// (시스템 뒤로가기는 화면의 PopScope 가 따로 막아야 합니다.)
/// 링크로 바로 열려 닫을 화면이 없을 수 있는 화면은 [onBack] 으로 왼쪽 버튼 동작을 바꿉니다. 없으면 `context.pop` 입니다.
/// [title] 을 주면 가운데에 제목을 보여주고, [showClose] 가 true 이면 왼쪽을 뒤로가기(<) 대신 닫기(X)로 바꿉니다.
class MoaAppBar extends AppBar {
  MoaAppBar({
    super.key,
    super.actions,
    String? title,
    bool showClose = false,
    bool backEnabled = true,
    VoidCallback? onBack,
  }) : super(
         backgroundColor: MoaColors.page,
         surfaceTintColor: MoaColors.page,
         scrolledUnderElevation: 0,
         centerTitle: true,
         title: title == null ? null : Text(title, style: MoaText.titleS),
         // Figma 의 왼쪽 여백(16px)에 맞춥니다.
         leadingWidth: 60,
         // 뒤로가기(context.pop)에 BuildContext 가 필요해서 Builder 로 감쌉니다.
         leading: Builder(
           builder: (context) => Padding(
             padding: const EdgeInsets.only(left: 12),
             child: IconButton(
               onPressed: backEnabled ? onBack ?? context.pop : null,
               icon: SvgPicture.asset(
                 showClose
                     ? 'assets/icons/x.svg'
                     : 'assets/icons/caret_left.svg',
                 width: 20,
                 height: 20,
               ),
             ),
           ),
         ),
       );
}
