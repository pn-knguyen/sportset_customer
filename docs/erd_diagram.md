# SƠ ĐỒ THỰC THỂ QUAN HỆ & CẤU TRÚC CƠ SỞ DỮ LIỆU (ERD SCHEMA)
## Dự án: Sportset Customer

Tài liệu này cung cấp mô hình thực thể quan hệ cơ sở dữ liệu **ERD (Entity-Relationship Diagram)** hoàn chỉnh và đặc tả chi tiết cấu trúc dữ liệu (**Database Schema**) được sử dụng trên nền tảng Firebase Firestore của ứng dụng **Sportset Customer**.

---

## 1. Sơ Đồ Thực Thể Quan Hệ (ERD Diagram)

Sơ đồ Crow's Foot dưới đây mô tả cấu trúc các tài liệu (Documents/Collections) và mối liên kết logic nghiệp vụ giữa các thực thể trong cơ sở dữ liệu hệ thống:

```mermaid
erDiagram
    %% =======================================================
    %% ĐỊNH NGHĨA THỰC THỂ VÀ THUỘC TÍNH CHI TIẾT
    %% =======================================================
    CUSTOMERS {
        string uid PK "Mã định danh khách hàng (Firebase Auth UID)"
        string fullName "Họ và tên khách hàng"
        string email "Địa chỉ Email"
        string phone "Số điện thoại liên hệ"
        string gender "Giới tính (Male/Female/Other)"
        string dob "Ngày sinh (dd/mm/yyyy)"
        string photoUrl "Đường dẫn ảnh đại diện cá nhân"
        timestamp createdAt "Thời gian tạo tài khoản"
    }

    SPORTS {
        string sportId PK "Mã danh mục bộ môn thể thao"
        string name "Tên bộ môn (Bóng đá, Cầu lông, Tennis...)"
        string image "Hình ảnh đại diện bộ môn"
        boolean isVisible "Trạng thái hiển thị trên giao diện"
        timestamp createdAt "Thời gian tạo danh mục"
    }

    FACILITIES {
        string facilityId PK "Mã cơ sở thể thao lớn"
        string name "Tên cơ sở thể thao"
        string address "Địa chỉ chi tiết cơ sở"
        double latitude "Vĩ độ bản đồ GPS"
        double longitude "Kinh độ bản đồ GPS"
        string openTime "Giờ mở cửa (HH:mm)"
        string closeTime "Giờ đóng cửa (HH:mm)"
        string phone "Số điện thoại hotline cơ sở"
        array amenities "Mảng các tiện ích chung (wifi, parking, shower...)"
        double rating "Rating trung bình của cơ sở"
        string image "Hình ảnh đại diện cơ sở"
        timestamp createdAt "Thời gian tạo cơ sở"
    }

    COURTS {
        string courtId PK "Mã sân tập cụ thể"
        string facilityId FK "Mã cơ sở chủ quản"
        string name "Tên cụ thể của sân chơi"
        string sportType "Loại bộ môn thể thao (bóng đá, cầu lông...)"
        int pricePerHour "Đơn giá tiêu chuẩn mỗi giờ chơi"
        string status "Trạng thái hoạt động (available, maintenance, closed)"
        string image "Ảnh đại diện chính của sân"
        array images "Mảng album ảnh chi tiết về sân chơi"
        array amenities "Mảng các tiện ích riêng biệt của sân"
        string description "Mô tả chi tiết đặc điểm sân"
        array weekdayPricing "Khung giá ngày thường theo khung giờ"
        array weekendPricing "Khung giá cuối tuần theo khung giờ"
        array subCourts "Danh sách các sân con trực thuộc (ví dụ: Sân 5A, Sân 5B)"
    }

    BOOKINGS {
        string bookingId PK "Mã đơn đặt sân duy nhất"
        string userId FK "Mã khách hàng đặt lịch (CUSTOMERS.uid)"
        string courtId FK "Mã sân tập được thuê (COURTS.courtId)"
        string courtName "Tên sân chơi tại thời điểm đặt"
        string courtAddress "Địa chỉ sân tập tại thời điểm đặt"
        string courtImageUrl "Ảnh đại diện sân tại thời điểm đặt"
        string facilityId FK "Mã cơ sở sở hữu sân (FACILITIES.facilityId)"
        string facilityName "Tên cơ sở chủ quản"
        string sportType "Loại bộ môn chơi"
        string subCourtName "Tên sân con cụ thể được thuê"
        map selectedDate "Bản đồ lưu thông tin Ngày/Tháng/Năm chơi"
        map selectedSlot "Bản đồ thông tin khung giờ & đơn giá slot"
        string duration "Tổng thời lượng thuê (ví dụ: '1.5 hours')"
        int slotPrice "Đơn giá của khung giờ đã chọn"
        int totalPrice "Tổng chi phí cuối cùng phải trả"
        int basePrice "Tổng chi phí gốc chưa giảm trừ"
        int discountAmount "Số tiền được giảm ưu đãi"
        string voucherId FK "Mã voucher được sử dụng (VOUCHERS.voucherId)"
        string voucherCode "Mã code của voucher áp dụng"
        string voucherTitle "Tên chương trình voucher ưu đãi"
        string paymentMethod "Phương thức thanh toán (momo, zalopay, direct...)"
        string status "Trạng thái đơn (pending, confirmed, completed, cancelled)"
        string paymentStatus "Trạng thái tiền (pending, paid)"
        boolean hasReview "Đã viết đánh giá chất lượng chưa"
        timestamp createdAt "Thời điểm khởi tạo đơn đặt"
        timestamp updatedAt "Thời điểm cập nhật đơn gần nhất"
    }

    VOUCHERS {
        string voucherId PK "Mã giảm giá độc bản"
        string code "Mã viết in hoa để người dùng nhập (ví dụ: SPORT50)"
        string title "Tên chương trình khuyến mãi"
        string discountType "Phân loại giảm giá (percent hoặc fixed)"
        int discountValue "Giá trị giảm (phần trăm hoặc số tiền mặt)"
        int minOrderValue "Giá trị đơn hàng tối thiểu để áp dụng"
        string facilityId FK "Mã cơ sở áp dụng riêng biệt (nếu có)"
        string facilityName "Tên cơ sở áp dụng riêng biệt"
        int totalQuantity "Tổng số lượng mã trong kho"
        int usedQuantity "Số lượng mã đã được sử dụng"
        int maxPerUser "Số lượt sử dụng tối đa của mỗi khách hàng"
        timestamp startDate "Ngày bắt đầu chương trình khuyến mãi"
        timestamp endDate "Ngày kết thúc chương trình khuyến mãi"
        boolean isActive "Trạng thái kích hoạt hoạt động"
        timestamp createdAt "Thời điểm tạo mã voucher"
    }

    REVIEWS {
        string reviewId PK "Mã nhận xét khách hàng"
        string userId FK "Mã khách hàng viết nhận xét (CUSTOMERS.uid)"
        string userName "Họ tên khách hàng tại thời điểm viết"
        string userAvatar "Ảnh đại diện khách hàng"
        string fieldId FK "Mã sân nhận đánh giá (COURTS.courtId)"
        string bookingId FK "Mã đơn đặt sân tương ứng (BOOKINGS.bookingId)"
        string fieldName "Tên sân chơi nhận đánh giá"
        int rating "Điểm đánh giá chất lượng (1-5 sao)"
        string review "Nội dung nhận xét chi tiết"
        array images "Album ảnh thực tế do khách đính kèm"
        boolean replied "Đã được cơ sở phản hồi hay chưa"
        string reply "Nội dung phản hồi từ phía cơ sở"
        timestamp createdAt "Thời điểm gửi đánh giá"
    }

    FAVORITES {
        string courtId PK "Mã sân tập yêu thích"
        string facilityId FK "Mã cơ sở chủ quản"
        string name "Tên sân yêu thích"
        string image "Hình ảnh sân yêu thích"
        string address "Địa chỉ sân tập"
        double rating "Điểm đánh giá trung bình của sân"
        string price "Mức giá thuê hiển thị"
        timestamp savedAt "Thời điểm lưu vào danh sách yêu thích"
    }

    PASSWORD_RESET_OTPS {
        string email PK "Địa chỉ Email yêu cầu khôi phục mật khẩu"
        string otp "Mã số xác thực OTP gồm 6 chữ số ngẫu nhiên"
        boolean verified "Trạng thái đã xác minh thành công"
        timestamp createdAt "Thời điểm khởi tạo OTP"
        timestamp expiresAt "Thời điểm hết hạn hiệu lực mã OTP"
    }

    %% =======================================================
    %% MỐI QUAN HỆ LOGIC NGHIỆP VỤ (RELATIONSHIPS)
    %% =======================================================
    CUSTOMERS ||--o{ BOOKINGS : "thực hiện đặt (1:N)"
    COURTS ||--o{ BOOKINGS : "được thuê trong (1:N)"
    FACILITIES ||--|{ COURTS : "sở hữu và quản lý (1:N)"
    FACILITIES ||--o{ VOUCHERS : "phát hành riêng (1:N)"
    CUSTOMERS ||--o{ REVIEWS : "đăng tải nhận xét (1:N)"
    COURTS ||--o{ REVIEWS : "nhận ý kiến đánh giá (1:N)"
    BOOKINGS ||--o? REVIEWS : "có nhận xét cụ thể (1:0..1)"
    CUSTOMERS ||--o{ FAVORITES : "lưu danh sách (1:N - subcollection)"
    COURTS ||--o{ FAVORITES : "được lưu trong (1:N)"
    CUSTOMERS ||--o? PASSWORD_RESET_OTPS : "yêu cầu cấp OTP (1:0..1)"
    VOUCHERS ||--o{ BOOKINGS : "được áp dụng trong (1:N)"
```

---

## 2. Đặc Tả Chi Tiết Cơ Sở Dữ Liệu (Firestore Collections Schema)

Firebase Firestore là cơ sở dữ liệu tài liệu NoSQL. Dưới đây là đặc tả chi tiết cấu trúc dữ liệu vật lý của từng collection:

### 2.1. Collection: `customers`
Lưu trữ toàn bộ hồ sơ thông tin và dữ liệu xác thực của khách hàng.
* **Document ID**: `uid` (Trùng khớp với mã UID được tạo tự động bởi Firebase Authentication).

| Tên Trường (Field) | Kiểu Dữ Liệu | Khóa | Ràng Buộc | Mô Tả & Ví Dụ |
| :--- | :--- | :---: | :--- | :--- |
| `uid` | `string` | **PK** | Duy nhất, Không rỗng | Mã định danh khách hàng. Ví dụ: `uX82Kld92mN...` |
| `fullName` | `string` | | Không rỗng | Họ và tên khách hàng. Ví dụ: `"Nguyễn Văn A"` |
| `email` | `string` | | Định dạng email hợp lệ | Địa chỉ Email đăng ký. Ví dụ: `"nguyena@gmail.com"` |
| `phone` | `string` | | Định dạng SĐT | Số điện thoại liên lạc. Ví dụ: `"0987654321"` |
| `gender` | `string` | | `"Male" / "Female" / "Other"`| Giới tính của khách hàng. |
| `dob` | `string` | | Định dạng `dd/mm/yyyy` | Ngày/Tháng/Năm sinh. Ví dụ: `"15/08/2000"` |
| `photoUrl` | `string` | | Đường dẫn URL ảnh hợp lệ | Ảnh đại diện của khách hàng (lưu trên Cloud Storage). |
| `createdAt` | `timestamp` | | Server Timestamp | Ngày giờ tài khoản được tạo lập thành công. |

---

### 2.2. Collection: `facilities`
Lưu trữ thông tin chi tiết về các cơ sở, câu lạc bộ, hoặc cụm sân thể thao lớn.
* **Document ID**: `facilityId` (Chuỗi ngẫu nhiên tự tạo của Firestore).

| Tên Trường (Field) | Kiểu Dữ Liệu | Khóa | Ràng Buộc | Mô Tả & Ví Dụ |
| :--- | :--- | :---: | :--- | :--- |
| `facilityId` | `string` | **PK** | Duy nhất, Không rỗng | Mã cơ sở thể thao lớn. Ví dụ: `fac_01` |
| `name` | `string` | | Không rỗng | Tên thương hiệu cơ sở. Ví dụ: `"Cơ sở Thể Thao Antigravity"` |
| `address` | `string` | | Không rỗng | Địa chỉ cụ thể. Ví dụ: `"123 Đường ABC, Quận 1, TP. HCM"` |
| `latitude` | `double` | | Từ -90 đến 90 | Vĩ độ định vị Google Maps. Ví dụ: `10.7769` |
| `longitude` | `double` | | Từ -180 đến 180 | Kinh độ định vị Google Maps. Ví dụ: `106.7009` |
| `openTime` | `string` | | Định dạng `HH:mm` | Giờ mở cửa hàng ngày. Ví dụ: `"05:00"` |
| `closeTime` | `string` | | Định dạng `HH:mm` | Giờ đóng cửa hàng ngày. Ví dụ: `"22:00"` |
| `phone` | `string` | | Định dạng SĐT | Hotline đặt sân của cơ sở. Ví dụ: `"0283829000"` |
| `amenities` | `array (string)`| | Chứa danh sách chuỗi | Tiện ích chung. Ví dụ: `["Wifi miễn phí", "Bãi đỗ xe ô tô", "Phòng thay đồ"]` |
| `rating` | `double` | | Từ 1.0 đến 5.0 | Điểm đánh giá trung bình cộng. Ví dụ: `4.8` |
| `image` | `string` | | URL ảnh | Ảnh bìa đại diện giới thiệu cơ sở thể thao. |
| `createdAt` | `timestamp`| | | Thời điểm cơ sở đăng ký hoạt động trên hệ thống. |

---

### 2.3. Collection: `courts`
Lưu trữ thông tin các sân chơi thể thao cụ thể (sân bóng đá cỏ nhân tạo, sân cầu lông trong nhà...).
* **Document ID**: `courtId` (Chuỗi ngẫu nhiên tự tạo của Firestore).

| Tên Trường (Field) | Kiểu Dữ Liệu | Khóa | Ràng Buộc | Mô Tả & Ví Dụ |
| :--- | :--- | :---: | :--- | :--- |
| `courtId` | `string` | **PK** | Duy nhất | Mã định danh sân chơi. |
| `facilityId` | `string` | **FK** | Tham chiếu `facilities` | Mã cơ sở chủ quản quản lý trực tiếp sân này. |
| `name` | `string` | | Không rỗng | Tên hiển thị của sân. Ví dụ: `"Sân Cầu Lông Cao Cấp Thống Nhất"` |
| `sportType` | `string` | | Trùng danh mục `sports` | Loại bộ môn chơi. Ví dụ: `"Badminton"` hoặc `"Football"` |
| `pricePerHour` | `int` | | >= 0 | Đơn giá chuẩn mỗi giờ chơi (VND). Ví dụ: `150000` |
| `status` | `string` | | `"available"/"maintenance"`| Trạng thái hoạt động phục vụ khách. |
| `image` | `string` | | URL ảnh | Ảnh đại diện chính của sân chơi. |
| `images` | `array (string)`| | Danh sách URL | Album ảnh chi tiết góc nhìn sân tập. |
| `amenities` | `array (string)`| | | Tiện ích đi kèm riêng biệt của sân. |
| `description` | `string` | | | Đoạn văn mô tả chi tiết chất lượng, vật liệu sân. |
| `weekdayPricing` | `array (map)` | | Chứa khung giờ + giá | Cấu hình giá chi tiết theo từng khung giờ ngày thường. |
| `weekendPricing` | `array (map)` | | Chứa khung giờ + giá | Cấu hình giá chi tiết cho các khung giờ cao điểm cuối tuần. |
| `subCourts` | `array (map)` | | | Danh sách sân nhỏ bên trong. Ví dụ: `[{"id": "sub_1", "name": "Sân Số 1"}]` |

---

### 2.4. Collection: `bookings`
Tài liệu quan trọng nhất lưu trữ các giao dịch đặt sân chơi và lịch sử thanh toán của khách hàng.
* **Document ID**: `bookingId` (Chuỗi ngẫu nhiên tự tạo của Firestore).

| Tên Trường (Field) | Kiểu Dữ Liệu | Khóa | Ràng Buộc | Mô Tả & Ví Dụ |
| :--- | :--- | :---: | :--- | :--- |
| `bookingId` | `string` | **PK** | Duy nhất | Mã đơn đặt sân duy nhất hệ thống. Ví dụ: `BK_170948922` |
| `userId` | `string` | **FK** | Tham chiếu `customers` | Khách hàng đặt mua dịch vụ này. |
| `courtId` | `string` | **FK** | Tham chiếu `courts` | Sân được thuê phục vụ khách hàng. |
| `courtName` | `string` | | | Tên sân lưu vết tại thời điểm tạo đơn. |
| `courtAddress` | `string` | | | Địa chỉ sân chơi để hiển thị trên hóa đơn/QR. |
| `courtImageUrl` | `string` | | | Ảnh đại diện sân chơi tại thời điểm đặt lịch. |
| `facilityId` | `string` | **FK** | Tham chiếu `facilities` | Cơ sở chủ quản phục vụ. |
| `facilityName` | `string` | | | Tên cơ sở lưu vết. |
| `sportType` | `string` | | | Bộ môn thể thao được đặt lịch. |
| `subCourtName` | `string` | | Không rỗng | Sân con cụ thể được thuê. Ví dụ: `"Sân Số 2"` |
| `selectedDate` | `map` | | Bắt buộc | Lưu trữ ngày chơi: `{"day": 25, "month": 5, "year": 2026, "weekday": "Monday"}` |
| `selectedSlot` | `map` | | Bắt buộc | Khung giờ chơi: `{"start": "17:00", "end": "18:30", "price": 180000}` |
| `duration` | `string` | | | Tổng thời lượng đã quy đổi. Ví dụ: `"1.5 hours"` |
| `slotPrice` | `int` | | | Giá trị thuê của khung giờ đó. |
| `basePrice` | `int` | | >= 0 | Tổng tiền sân gốc (chưa áp dụng ưu đãi giảm giá). |
| `discountAmount` | `int` | | >= 0 | Số tiền được giảm nhờ voucher. Ví dụ: `30000` |
| `totalPrice` | `int` | | `= basePrice - discount` | Tổng số tiền thanh toán thực tế cuối cùng. |
| `voucherId` | `string` | **FK** | Tham chiếu `vouchers` | Mã ID của voucher đã áp dụng (nếu có). |
| `voucherCode` | `string` | | | Mã Code viết hoa của voucher dùng lưu vết. |
| `voucherTitle` | `string` | | | Tên hiển thị chương trình voucher đã dùng. |
| `paymentMethod` | `string` | | `"momo"/"zalopay"/"direct"`| Kênh thanh toán lựa chọn. |
| `status` | `string` | | `"pending"/"confirmed"/...`| Trạng thái đơn: Chờ duyệt, Thành công, Đã hủy, Hoàn thành. |
| `paymentStatus` | `string` | | `"pending"/"paid"` | Trạng thái thanh toán của hóa đơn. |
| `hasReview` | `boolean` | | Mặc định `false` | Khách hàng đã gửi phản hồi sao cho đơn đặt này chưa. |
| `createdAt` | `timestamp`| | Server Timestamp | Ngày giờ thực hiện thao tác đặt chỗ trực tuyến. |
| `updatedAt` | `timestamp`| | | Ngày giờ giao dịch được cập nhật trạng thái mới. |

---

### 2.5. Collection: `vouchers`
Lưu trữ thông tin các mã ưu đãi giảm giá phát hành bởi hệ thống hoặc cơ sở thể thao cụ thể.
* **Document ID**: `voucherId` (Chuỗi ngẫu nhiên tự tạo của Firestore).

| Tên Trường (Field) | Kiểu Dữ Liệu | Khóa | Ràng Buộc | Mô Tả & Ví Dụ |
| :--- | :--- | :---: | :--- | :--- |
| `voucherId` | `string` | **PK** | Duy nhất | Mã voucher ngẫu nhiên hệ thống. |
| `code` | `string` | | In hoa, Duy nhất | Mã code nhập thủ công. Ví dụ: `"CHAOMUNG"` |
| `title` | `string` | | Không rỗng | Tên voucher. Ví dụ: `"Giảm 20% cho khách hàng mới"` |
| `discountType` | `string` | | `"percent" / "fixed"` | Đơn vị tính ưu đãi (phần trăm % hoặc số tiền mặt). |
| `discountValue` | `int` | | > 0 | Mức ưu đãi. Ví dụ: `20` (cho percent) hoặc `50000` (cho fixed). |
| `minOrderValue` | `int` | | >= 0 | Giá trị đơn hàng tối thiểu cần đạt để áp dụng mã giảm giá. |
| `facilityId` | `string` | **FK** | Tham chiếu `facilities` | null nếu áp dụng toàn sàn; có ID nếu chỉ áp dụng tại 1 cơ sở. |
| `facilityName` | `string` | | | Tên cơ sở áp dụng riêng biệt. |
| `totalQuantity` | `int` | | >= `usedQuantity` | Tổng số lượt mã phát hành trong kho. |
| `usedQuantity` | `int` | | Mặc định `0` | Tổng số lượt mã đã được áp dụng đặt sân thành công. |
| `maxPerUser` | `int` | | >= 1 | Giới hạn số lượt sử dụng tối đa của 1 tài khoản khách hàng. |
| `startDate` | `timestamp`| | | Ngày giờ mã giảm giá bắt đầu có hiệu lực sử dụng. |
| `endDate` | `timestamp`| | > `startDate` | Ngày giờ mã giảm giá hết hiệu lực sử dụng. |
| `isActive` | `boolean` | | | `true`: Khả dụng; `false`: Bị vô hiệu hóa tạm thời. |
| `createdAt` | `timestamp`| | | Thời điểm tạo và đăng cấu hình mã voucher lên hệ thống. |

---

### 2.6. Collection: `reviews`
Lưu trữ đánh giá chất lượng dịch vụ của khách hàng sau khi hoàn tất lịch chơi thể thao.
* **Document ID**: `reviewId` (Chuỗi ngẫu nhiên tự tạo của Firestore).

| Tên Trường (Field) | Kiểu Dữ Liệu | Khóa | Ràng Buộc | Mô Tả & Ví Dụ |
| :--- | :--- | :---: | :--- | :--- |
| `reviewId` | `string` | **PK** | Duy nhất | Mã nhận xét ngẫu nhiên. |
| `userId` | `string` | **FK** | Tham chiếu `customers` | Mã khách hàng viết nhận xét này. |
| `userName` | `string` | | | Họ tên khách hàng được trích xuất nhanh tại thời điểm đánh giá. |
| `userAvatar` | `string` | | | Ảnh đại diện khách hàng lưu vết nhanh. |
| `fieldId` | `string` | **FK** | Tham chiếu `courts` | Mã sân chơi nhận đánh giá chất lượng này. |
| `bookingId` | `string` | **FK** | Tham chiếu `bookings` | Mã đơn đặt sân tương ứng thực tế đã hoàn thành. |
| `fieldName` | `string` | | | Tên sân tập nhận đánh giá lưu vết nhanh. |
| `rating` | `int` | | Từ 1 đến 5 | Điểm số đánh giá chất lượng (1 sao đến 5 sao). |
| `review` | `string` | | | Đoạn nhận xét, bình luận cụ thể của khách hàng. |
| `images` | `array (string)`| | | Các liên kết ảnh chụp thực trạng sân được đăng kèm. |
| `replied` | `boolean` | | | Trạng thái chủ cơ sở đã viết lời phản hồi hay chưa. |
| `reply` | `string` | | | Nội dung lời phản hồi từ đại diện cơ sở thể thao. |
| `createdAt` | `timestamp`| | Server Timestamp | Ngày giờ gửi đánh giá lên máy chủ. |

---

### 2.7. Collection: `favorites` (Subcollection cấu trúc lồng)
Danh sách lưu trữ các sân bóng hoặc sân tập được người dùng đánh dấu yêu thích để truy cập nhanh.
* **Đường dẫn lồng dữ liệu (Subcollection Path)**: `/favorites/{userId}/courts/{courtId}`
* **Document ID**: `courtId` (Khớp với ID của sân tập trong collection `courts`).

| Tên Trường (Field) | Kiểu Dữ Liệu | Khóa | Ràng Buộc | Mô Tả & Ví Dụ |
| :--- | :--- | :---: | :--- | :--- |
| `courtId` | `string` | **PK** | Trùng `courts` | Mã định danh sân chơi được đánh dấu yêu thích. |
| `facilityId` | `string` | **FK** | Tham chiếu `facilities` | Cơ sở quản lý sân chơi yêu thích này. |
| `name` | `string` | | | Tên sân tập yêu thích để hiển thị trực tiếp. |
| `image` | `string` | | | Ảnh bìa sân để hiển thị trực tiếp. |
| `address` | `string` | | | Địa chỉ sân để hiển thị trực tiếp. |
| `rating` | `double` | | | Điểm chấm trung bình của sân tại thời điểm đánh dấu. |
| `price` | `string` | | | Chuỗi ký tự giá thuê tham khảo. Ví dụ: `"150.000đ/giờ"` |
| `savedAt` | `timestamp`| | Server Timestamp | Thời gian khách hàng nhấn nút yêu thích địa điểm này. |

---

### 2.8. Collection: `sports`
Lưu trữ danh mục các bộ môn thể thao chính đang được nền tảng hỗ trợ dịch vụ.
* **Document ID**: `sportId` (Mã viết thường đại diện cho môn thể thao). Ví dụ: `football`, `badminton`, `tennis`, `basketball`.

| Tên Trường (Field) | Kiểu Dữ Liệu | Khóa | Ràng Buộc | Mô Tả & Ví Dụ |
| :--- | :--- | :---: | :--- | :--- |
| `sportId` | `string` | **PK** | Duy nhất, Không rỗng | Mã bộ môn viết thường không dấu. Ví dụ: `"badminton"` |
| `name` | `string` | | Không rỗng | Tên hiển thị chính thức của bộ môn. Ví dụ: `"Cầu lông"` |
| `image` | `string` | | URL ảnh | Liên kết ảnh icon hoặc hình ảnh minh họa cho bộ môn. |
| `isVisible` | `boolean` | | | Cho phép hiển thị danh mục này ra trang chính hay không. |
| `createdAt` | `timestamp`| | | Ngày giờ khởi tạo danh mục bộ môn trên hệ thống. |

---

### 2.9. Collection: `password_reset_otps`
Hỗ trợ quản lý và xác thực tạm thời các mã số OTP dùng cho quy trình khôi phục mật khẩu.
* **Document ID**: `email` (Địa chỉ email đăng ký tài khoản cần khôi phục).

| Tên Trường (Field) | Kiểu Dữ Liệu | Khóa | Ràng Buộc | Mô Tả & Ví Dụ |
| :--- | :--- | :---: | :--- | :--- |
| `email` | `string` | **PK** | Định dạng Email | Địa chỉ email của khách hàng yêu cầu khôi phục mật khẩu. |
| `otp` | `string` | | Đúng 6 số | Mã xác thực OTP ngẫu nhiên. Ví dụ: `"593021"` |
| `verified` | `boolean` | | Mặc định `false` | Đánh dấu khách đã nhập đúng mã OTP này và đã được duyệt. |
| `createdAt` | `timestamp`| | Server Timestamp | Thời gian khởi tạo mã OTP để gửi email về cho khách. |
| `expiresAt` | `timestamp`| | > `createdAt` | Thời điểm hết hạn mã OTP (thông thường hiệu lực là 5-10 phút). |

---

## 3. Các Ràng Buộc và Thiết Kế Nghiệp Vụ NoSQL Thông Minh

Trong quá trình xây dựng hệ thống cơ sở dữ liệu Firebase Firestore, một số thiết kế NoSQL đặc thù đã được áp dụng nhằm nâng cao hiệu năng truy vấn của ứng dụng di động:

1. **Lưu Vết Thông Tin (Denormalization - Phi Chuẩn Hóa)**:
   * Trên các tài liệu như `bookings` và `reviews`, các trường như `courtName`, `courtAddress`, `userName`, `userAvatar`, `fieldName` được sao chép trực tiếp vào đơn đặt thay vì chỉ lưu mã ID.
   * **Ưu điểm**: Khi khách hàng xem lại danh sách đơn hàng đã đặt hoặc trang lịch sử, hệ thống không cần thực hiện thêm các thao tác truy vấn (join) sang các bảng khác để tìm lại tên sân hay ảnh. Dữ liệu được hiển thị lập tức trong một lần đọc duy nhất, tiết kiệm băng thông và tối ưu hóa thời gian tải ứng dụng.

2. **Cơ Chế Chống Trùng Lịch Thời Gian Thực (Anti-Double-Booking)**:
   * Thuộc tính `selectedSlot` lưu cấu hình giờ thuê kết hợp cùng `selectedDate`. 
   * Khi người dùng chuẩn bị thanh toán đơn hàng mới, hệ thống thực hiện truy vấn điều kiện song song kiểm tra trong collection `bookings` các bản ghi có trạng thái `confirmed` hoặc `pending` có trùng khớp đồng thời các thuộc tính `courtId`, ngày chơi (`selectedDate`) và khung giờ (`selectedSlot.start` và `selectedSlot.end`) hay không trước khi xác nhận tạo đơn hàng mới.

3. **Cập Nhật Điểm Số Đánh Giá (Atomic Increment for Average Rating)**:
   * Điểm số `rating` tại các cơ sở `facilities` và sân chơi `courts` được cập nhật tự động khi khách hàng thực hiện gửi nhận xét đánh giá mới trong collection `reviews`.
   * Hệ thống tính toán điểm trung bình mới bằng công thức tích lũy số lượng và tổng điểm để cập nhật trực tiếp vào tài liệu cơ sở, đảm bảo thông tin hiển thị cho những người dùng tiếp theo luôn là chính xác nhất.

4. **Tổ Chức Danh Sách Yêu Thích Theo Dạng Subcollection**:
   * Danh mục yêu thích `favorites` được phân hoạch chi tiết theo cấu trúc lồng trực thuộc từng mã tài khoản người dùng (`/favorites/{userId}/courts/{courtId}`). 
   * **Ưu điểm**: Phân vùng dữ liệu cô lập tuyệt đối cho từng người dùng, ngăn ngừa việc tải toàn bộ danh mục yêu thích khổng lồ của cả hệ thống về máy khách hàng, nâng cao tính bảo mật và quyền riêng tư cá nhân.
