// import 'package:car_route/modules/global/widgets/global_text.dart';
// import 'package:car_route/modules/home_page/controller/home_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// class LocationRoadInfo extends StatelessWidget {
//   const LocationRoadInfo({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer(builder: (context, ref, child) {
//       final state = ref.watch(homeController);
//       if (state.roadInfo == null) {
//         return const SizedBox.shrink();
//       }
//       return Align(
//         alignment: Alignment.bottomCenter,
//         child: Container(
//           padding: EdgeInsets.symmetric(
//             horizontal: 20.w,
//             vertical: 20.h,
//           ),
//           width: MediaQuery.of(context).size.width,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(10.r),
//               topRight: Radius.circular(10.r),
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildRow("Start Location", state.roadInfo?.startPointName ?? ""),
//               SizedBox(height: 6.h),
//               _buildRow(
//                   "Destination Location", state.roadInfo?.endPointName ?? ""),
//               SizedBox(height: 6.h),
//               _buildRow("Distance", state.roadInfo?.distance ?? ""),
//               SizedBox(height: 6.h),
//               _buildRow("Duration", state.roadInfo?.time ?? ""),
//             ],
//           ),
//         ),
//       );
//     });
//   }
//
//   Widget _buildRow(String title, String value) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: [
//         Flexible(
//           child: GlobalText(
//             "$title : ",
//             color: Colors.black,
//             fontSize: 12,
//           ),
//         ),
//         Expanded(
//           child: GlobalText(
//             value,
//             color: Colors.black.withOpacity(0.4),
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }
// }
