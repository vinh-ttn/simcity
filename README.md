# SimCity Mod for JX1 Linux

—vinhsmoke—

Phiên bản hiện tại: **5.3**

Download: [main.tar.gz](https://github.com/vinh-ttn/simcity/archive/refs/heads/main.tar.gz)

### Đóng góp

-   Dev chính: [Vinh TTN](https://www.facebook.com/groups/800085930700601/user/1576281122)
-   Tọa độ 116 maps, bổ sung câu chat: [Đỗ Gia Bảo](https://www.facebook.com/groups/800085930700601/user/100002639166984/)
-   Tọa độ Biện Kinh, Phượng Tường, Đại Lý: [Duy Ngô](https://www.facebook.com/groups/800085930700601/user/61551322996134/)
-   Tọa độ Lâm An: [Huy Nguyen](https://www.facebook.com/groups/800085930700601/user/100004608648396/)


## A. Cài đặt/cập nhật qua [1ClickVMFull](https://docs.google.com/document/d/1BUtlCyJdIg-Dc15EZLYU7dMAcGA4wzcZDMBrM3dRpcc/edit?usp=sharing)

Yêu cầu game server của bạn phải có kết nối internet

1\) Trong app QuanLyServer, hãy chắc chắn đúng phiên bản server đang sử dụng, sau đó nhấn nút **Up** màu đỏ

2\) Cửa sổ xác nhận sẽ hiện ra, gõ **co** và enter khi gặp câu hỏi xác nhận

3\) Sau đó điền vào **vinh-ttn/simcity** và enter để cập nhật từ github này

Xong, khởi động lại game server.

![](https://github.com/vinh-ttn/materials/blob/main/simcity/caidat_capnhat_simcity.gif)

## B. Cài đặt/cập nhật thủ công Thành Thị, Chiến Loạn và Kéo Xe

1\) Download file [main.tar.gz](https://github.com/vinh-ttn/simcity/archive/refs/heads/main.tar.gz) về, giải nén và chép toàn bộ vào thư mục gốc của server

2\) Xong. Khởi động server và tìm đến gần hiệu thuốc Tương Dương:

\* gặp Triệu Mẫn để sử dụng simcity

\* gặp Vô Kỵ để điều khiển kéo xe (+ nhận lệnh bài kéo xe\*)

## C. Cài đặt/cập nhật thủ công Tống Kim (Bảo vệ nguyên soái)

1\) Để có được NPC Triệu Mẫn và Vô Kỵ trong Tống Kim, cần mở file

`\script\battles\marshal\mission.lua`

2\) Tìm đến dòng (thứ 4-5 gì đó từ trên đếm xuống):

`Include("\\script\\battles\\marshal\\head.lua")`

và thêm vào dòng ngay sau đó

`Include("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua")`

3\) Tìm đế hàm dòng (173) của hàm function InitMission():

`BT_SetMissionName("Phương Thức Bảo Vệ Nguyên Soái”)`

ngay sau dòng đó, thêm vào dòng

`SimCityMainTongKim:addTongKimNpc()`

4\) Khởi động lại server, vào Tống Kim sẽ có sẵn NPC đang đánh nhau và Triệu Mẫn/Vô Kỵ để điều khiển

5\) (Không cần lắm) Vì mặc định của KingSoft/VNG, mỗi phe cần 1 người chơi để đánh bạn mới có điểm.\
Nếu bạn không muốn như vậy. Có thể xem hướng dẫn để chỉnh server lại như sau: <https://www.facebook.com/groups/volamquan/permalink/1264194464289743/>

## D. Giới thiệu tính năng

Chạy trên JX Server 8

**1) Thành thị:** thành thị sẽ trở nên nhộn nhịp với các gian hàng và các nhân sĩ võ lâm đi lại. Các nhân sĩ có thể đánh nhau bất cứ lúc nào. Ngoài ra bạn có thể gọi thêm quan binh tuần tra (nhưng cũng vô ích) hoặc các quái khách trên cõi giang hồ.

![](https://github.com/vinh-ttn/materials/blob/main/simcity/thanhthi.gif)

**2) Chiến loạn:** khi mở, nhân sĩ ở Tương Dương và Biện Kinh sẽ trực tiếp tiến vào thành để chiếm đoạt của cải. Gây nên 1 trận chiến vô cùng khốc liệt.

![](https://github.com/vinh-ttn/materials/blob/main/simcity/chienloan.gif)

**3) Tống Kim:** chiến trường ác liệt, còn gì tuyệt vời hơn với sự góp mặt của các nhân sĩ võ lâm khắp chốn ao hồ. Bạn có đủ khả năng sống sót không?

![](https://github.com/vinh-ttn/materials/blob/main/simcity/tongkim.gif)

**4) Kéo Xe:** bạn có thể gọi nhân sĩ theo sau cùng đi cho an tâm.

![](https://github.com/vinh-ttn/materials/blob/main/simcity/keoxe.gif)

## E. Thông tin thêm

### Kéo xe NPC

1) Nếu muốn tạo lệnh bài gọi xe nhanh đem theo bên mình (thay vì NPC Vô Kỵ) thì vào <https://jxoffline.github.io/jxtools/shopbuilder.d/>  để tạo thêm 1 vật phẩm với đường link tới file script

`\script\global\vinh\simcity\controllers\main.lua`

2) Nếu muốn thay đổi danh sách theo sau (hoặc tạo riêng cho mình) thì sửa file

`\script\global\vinh\simcity\plugins\pkeoxe.lua`

### NPC quá mạnh 

![](https://lh7-us.googleusercontent.com/docsz/AD_4nXctDkLIw67xDMciom4lw9DzdbTlcLTFPF0s57aM2Y4_AsVgtZUKGvjm68E4HK9dka3f3LTKdGHumHDsom9GgLVrWVQoaXZGlLCftrT9FNMKJEgl_0WBaUnjFO5fb4__zu2iQ83PfpFS7MEYFA-AESd1RuNg?key=my0UP0YCEuAhRT8eOcMeRw)

### Thay đổi giữa các phiên bản

|                          | Ngày       | Thay đổi                                                                                                                                                                                                                                                      |
| ------------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1.0 SimCity & Kéo Xe** | 09/2023    | (Mới) Mở **gian hàng và dân chúng đi lại** ở Tương Dương. <br>(Thêm) KéoXe                                                                                                                                                                                    |
| **2.0 Chiến Loạn**       | 10/2023    | (Mới) **Chiến loạn** - tấn công thành thị Biện Kinh (trong ra) và Tương Dương (ngoài vô)<br>(Mới) Quan binh tuần tra theo hàng ngũ<br>(Mới) Tình trạng kéo xe xuất hiện<br>(Sửa) Thêm vào các thành khác: Biện Kinh, Phượng Tường, Đại Lý, Lâm An             |
| **3.0 Tống Kim**         | 10/2023    | (Mới) **Tống Kim**: <br>_ thêm map bảo vệ nguyên soái <br>_ tính điểm và thông báo bảng xếp hạng <br>\* thêm Vô Kỵ phe Tống, Triệu Mẫn phe Kim<br>(Sửa) Thêm vào các thành khác: Thành Đô, Dương Châu<br>Chỉnh sửa các thành hiện tại để tối ưu đường đi      |
| **4.0**                  | 10/2023    | (Mới) **Thay đổi toàn bộ hệ thống code** để tiện đường thêm thắt sau này (gọi là plugin). Gọp kéo xe thành 1 plugin nhỏ của SimCity thay vì 2 mod khác nhau.                                                                                                  |
| **5.0 RC1**              | 12/11/2023 | (Mới) **nhân sĩ võ lâm có hình người chơi**, bao gồm vũ khí hoàng kim và chỉ sử dụng skill người chơi<br>(Sửa) danh sách tên lạ võ lâm<br>(Sửa) danh sách đối thoại võ lâm<br>(Sửa) chia cấp độ nhân sĩ theo máu cho chính xác (sơ cấp máu vẫn còn quá nhiều) |
| **5.1**                  | 20/07/2024 | (Mới) Thêm chức năng tạo bãi luyện công trong kéo xe. <br>(Sửa) Lỗi thanh máu khi chơi Tống Kim                                                                                                                                                               |
| **5.2**                  | 28/07/2024 | (Mới) Thêm 116 map từ bạn [Đỗ Gia Bảo](https://www.facebook.com/groups/800085930700601/user/100002639166984/) <br> (Mới) Tự động load NPC                                                                                                                     |
| **?**                    | ?          | (Mới) thêm công thành trong Thất Thành Đại Chiến<br>(Sửa) máu lại cho hợp lý vì không phải ai cũng xài đồ siêu nhân =))<br>(Sửa) thêm người chơi vào danh sách Bảng Xếp Hạng trong Tống Kim                                                                   |
