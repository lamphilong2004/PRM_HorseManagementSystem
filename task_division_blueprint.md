# 📋 BẢN ĐỒ PHÂN CHIA NHIỆM VỤ DỰ ÁN (PROJECT TASK DIVISION BLUEPRINT)
**Đề tài: Hệ thống quản lý giải đua ngựa (Horse Racing Tournament Management System - SU26SWP03)**

Bản tài liệu này được thiết kế nhằm giúp nhóm của bạn **phân chia công việc ngay lập tức** sau khi push mã nguồn Flutter này lên Git. Mã nguồn hiện tại đã dựng sẵn toàn bộ **10 Thực thể cốt lõi (Domain Models)** và khung giao diện **Premium Dark Gold** chuẩn chỉ.

---

## 🏗️ 1. Danh Sách 10 Thực Thể Core Đã Dựng Sẵn (Domain Models)
Các thực thể này đã được định nghĩa tại file: `lib/features/home/domain/models/tournament_model.dart`.
Khi các thành viên khác làm màn hình UI của họ, họ chỉ cần import và sử dụng trực tiếp:

1.  **`HorseOwner`**: Quản lý Chủ ngựa, danh sách ngựa và tiền thưởng.
2.  **`Jockey`**: Quản lý Kỵ sĩ, mã kỵ sĩ, tỷ lệ thắng, trạng thái rảnh/bận.
3.  **`Horse`**: Quản lý ngựa đua, tuổi, chủ sở hữu, kỵ sĩ lái, tiến độ live.
4.  **`Tournament`**: Quản lý giải đấu, cơ cấu giải thưởng, địa điểm, trạng thái.
5.  **`Race`**: Cuộc đua, cự ly, trạng thái vòng đua, mã ngựa thắng.
6.  **`Registration`**: Đăng ký thi đấu của ngựa (Chờ duyệt, Đã duyệt, Từ chối).
7.  **`RaceResult`**: Kết quả về đích của từng mã ngựa, thời gian chạy.
8.  **`Prediction`**: Vé dự đoán (đặt cược điểm thưởng ảo) của Khán giả.
9.  **`Prize`**: Điểm thưởng phân phối cho Chủ ngựa, Kỵ sĩ hoặc Khán giả.
10. **`RefereeReport`**: Biên bản của Trọng tài, ghi nhận vi phạm, kiểm tra ngựa.

---

## 👥 2. Phân Chia Task Theo Vai Trò (Role-based Task Assignment)

Nhóm SWP/WDP nên chia thành các nhánh công việc (Feature Branches) tương ứng với 5 vai trò chính trong yêu cầu nghiệp vụ:

### 👤 Thành Viên 1: Trưởng Nhóm / Admin & Điều Phối (Admin Role)
*   **Mục tiêu:** Quản lý giải đấu, lập lịch đua, phê duyệt đăng ký ngựa và quản lý tài khoản.
*   **Các tính năng cần phát triển thêm (UI Screens):**
    *   Màn hình duyệt hồ sơ đăng ký thi đấu (`Registration`) từ các Chủ ngựa.
    *   Màn hình tạo mới Giải đấu (`Tournament`) và thêm các Vòng đua (`Race`).
    *   Màn hình phân công Trọng tài (`Referee`) quản lý từng trận đấu.
*   **Các file mẫu đã có hỗ trợ:** `Tournament` model, `Race` model.

### 👤 Thành Viên 2: Phân Hệ Chủ Ngựa (Horse Owner Role)
*   **Mục tiêu:** Đăng ký tài khoản, đăng ký ngựa tham gia giải, thuê Jockey và quản lý ví thưởng của ngựa.
*   **Các tính năng cần phát triển thêm (UI Screens):**
    *   Màn hình quản lý danh sách Ngựa sở hữu (`lib/features/owner/presentation/screens/my_horses_screen.dart`).
    *   Màn hình gửi yêu cầu đăng ký ngựa vào giải đấu đang mở (`Registration`).
    *   Màn hình tìm kiếm, liên hệ và thuê Jockey cho từng trận đua cụ thể.
*   **Các file mẫu đã có hỗ trợ:** `HorseOwner`, `Registration`, `Jockey` models.

### 👤 Thành Viên 3: Phân Hệ Kỵ Sĩ (Jockey Role)
*   **Mục tiêu:** Quản lý lịch phân công điều khiển ngựa, nhận lời mời thuê từ Chủ ngựa và theo dõi thành tích cá nhân.
*   **Các tính năng cần phát triển thêm (UI Screens):**
    *   Màn hình nhận và duyệt/từ chối lời mời điều khiển ngựa từ Chủ ngựa.
    *   Màn hình xem lịch thi đấu được phân công, thông tin ngựa mình sẽ điều khiển trong trận tiếp theo.
    *   Màn hình dashboard cá nhân: Thống kê số trận thắng, tỷ lệ thắng (%) và tiền thưởng tích lũy.
*   **Các file mẫu đã có hỗ trợ:** `Jockey` model.

### 👤 Thành Viên 4: Phân Hệ Trọng Tài (Race Referee Role)
*   **Mục tiêu:** Kiểm tra ngựa trước giờ chạy, theo dõi trực tiếp trận đấu, xử phạt vi phạm và lập biên bản kết quả.
*   **Các tính năng cần phát triển thêm (UI Screens):**
    *   Màn hình check-in ngựa trước khi xuất phát (xác nhận ngựa đủ sức khỏe chạy).
    *   Màn hình ghi nhận lỗi vi phạm (ví dụ: cản trở đường chạy, Jockey phạm quy) ngay trong khi trận đấu đang diễn ra.
    *   Màn hình lập biên bản trận đấu (`RefereeReport`) gửi lên hệ thống để Admin công bố kết quả.
*   **Các file mẫu đã có hỗ trợ:** `RefereeReport` model.

### 👤 Thành Viên 5: Phân Hệ Khán Giả (Spectator Role) - *ĐÃ HOÀN THÀNH BẢN DEMO XỊN*
*   **Mục tiêu:** Xem giải đấu, đặt cược điểm ảo và theo dõi trực tiếp mô phỏng đua ngựa thời gian thực.
*   **Trạng thái:** Đã được lập trình hoàn tất giao diện tuyệt đẹp với 4 tab:
    *   `SpectatorHomeScreen` (Khám Phá)
    *   `TournamentListScreen` (Lịch Đua)
    *   `LiveRaceScreen` (Live Standings chạy giả lập)
    *   `PredictionScreen` (Dự đoán, ví thưởng và hiệu ứng nhận thưởng)
*   **Cách sử dụng:** Thành viên 5 chịu trách nhiệm bảo trì, tối ưu hóa giao diện này và kết nối Backend API sau này.

---

## 📅 3. Kế Hoạch Tích Hợp Backend (BE Connection Roadmap)
Khi BE (C# / Java / Node.js) viết xong APIs, các thành viên sẽ thay thế lớp `MockAppState` (`lib/core/state/mock_app_state.dart`) bằng các HTTP API calls thực tế:
1.  Sử dụng thư viện `http` hoặc `dio` trong Flutter.
2.  Chuyển đổi các lớp Mock Data trong state thành các hàm gọi API:
    *   `fetchTournaments()` -> Gọi `GET /api/tournaments`
    *   `placePrediction()` -> Gọi `POST /api/predictions`
    *   `startRaceSimulation()` -> Kết nối qua **WebSockets (SignalR hoặc Socket.io)** để nhận tọa độ chạy thời gian thực từ Backend gửi về thay vì chạy Timer ảo.

---

Chúc nhóm các bạn SWP/WDP hoàn thành dự án xuất sắc và đạt điểm tối đa! 🚀
