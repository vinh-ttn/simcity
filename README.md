# SimCity Mod for JX1 Linux

—vinhsmoke—

Phiên bản hiện tại: **5.8** (cập nhật ngày [22/04/2025](CHANGELOG.md))

Download: [main.tar.gz](https://github.com/vinh-ttn/simcity/archive/refs/heads/main.tar.gz)

### Đóng góp

-   Dev chính: [Vinh TTN](https://www.facebook.com/groups/800085930700601/user/1576281122)
-   Tọa độ 116 maps, bổ sung câu chat: [Đỗ Gia Bảo](https://www.facebook.com/groups/800085930700601/user/100002639166984/)
-   Tọa độ Biện Kinh, Phượng Tường, Đại Lý: [Duy Ngô](https://www.facebook.com/groups/800085930700601/user/61551322996134/)
-   Tọa độ Lâm An: [Huy Nguyen](https://www.facebook.com/groups/800085930700601/user/100004608648396/)
-   [Hướng dẫn sửa lỗi mất đầu](https://github.com/vinh-ttn/simcity/issues/4) do thiếu res: [Trường Giang](https://www.facebook.com/groups/800085930700601/user/100003690357356)

## A. Cách cài đặt SimCity
### Cách 1: Cài đặt/cập nhật qua [1ClickVMFull](https://docs.google.com/document/d/1BUtlCyJdIg-Dc15EZLYU7dMAcGA4wzcZDMBrM3dRpcc/edit?usp=sharing)

Yêu cầu game server của bạn phải có kết nối internet

1\) Trong app QuanLyServer, hãy chắc chắn đúng phiên bản server đang sử dụng, sau đó nhấn nút **Up** màu đỏ

2\) Cửa sổ xác nhận sẽ hiện ra, gõ **co** và enter khi gặp câu hỏi xác nhận

3\) Sau đó điền vào **vinh-ttn/simcity** và enter để cập nhật từ github này

4\) Xong. Khởi động server và tìm đến gần hiệu thuốc Tương Dương:

* gặp Triệu Mẫn để sử dụng simcity

* gặp Vô Kỵ để điều khiển kéo xe

![](https://github.com/vinh-ttn/materials/blob/main/simcity/caidat_capnhat_simcity.gif)

### Cách 2: Cài đặt/cập nhật thủ công Thành Thị, Chiến Loạn và Kéo Xe

1\) Download file [main.tar.gz](https://github.com/vinh-ttn/simcity/archive/refs/heads/main.tar.gz) về, giải nén và chép toàn bộ vào thư mục gốc của server

2\) Xong. Khởi động server và tìm đến gần hiệu thuốc Tương Dương:

* gặp Triệu Mẫn để sử dụng simcity

* gặp Vô Kỵ để điều khiển kéo xe


## B. Sửa thần hành phù để điều khiển SimCity/Kéo Xe bất cứ đâu bao gồm Tống Kim

1\) Mở file thần hành phù

`\script\item\ib\shenxingfu.lua`

2\) Thêm 2 dòng này vào đầu file

`Include("\\script\\global\\vinh\\simcity\\head.lua")`
`Include("\\script\\global\\vinh\\simcity\\controllers\\thanhthi.lua")`

3\) Tìm đế hàm main() của file có đoạn:

`Thôn trang - Thành thị - Môn phái - CLD/gototown`

ngay sau dòng đó, thêm vào 2 dòng

`"Điều khiển SimCity/#SimCityMainThanhThi:mainMenu()",`

`"Điều khiển Kéo Xe/#SimCityKeoXe:mainMenu()",`

Xong. Khởi động lại server, vào Tống Kim và dùng Thần Hành Phù để điều khiển nhân sĩ giang hồ trong Tống Kim.

## C. (Không cần thiết) Thêm NPC Triệu Mẫn và Vô Kỵ trong Tống Kim Bảo Vệ Nguyên Soái
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

4\) Khởi động lại server, vào Tống Kim sẽ có Triệu Mẫn/Vô Kỵ để điều khiển

5\) (Không cần thiết) Vì mặc định của KingSoft/VNG, mỗi phe cần 1 người chơi để đánh bạn mới có điểm.\
Nếu bạn không muốn như vậy. Có thể xem [hướng dẫn để chỉnh server lại](https://www.facebook.com/groups/volamquan/permalink/1264194464289743/) cho có điểm.


## D. Giới thiệu tính năng

Chạy trên JX Server 6 và 8

**1) Thành thị:** thành thị sẽ trở nên nhộn nhịp với các gian hàng và các nhân sĩ võ lâm đi lại. Các nhân sĩ có thể đánh nhau bất cứ lúc nào. Ngoài ra bạn có thể gọi thêm quan binh tuần tra (nhưng cũng vô ích) hoặc các quái khách trên cõi giang hồ.

![](https://github.com/vinh-ttn/materials/blob/main/simcity/thanhthi.gif)

**2) Chiến loạn:** khi mở, nhân sĩ ở Tương Dương và Biện Kinh sẽ trực tiếp tiến vào thành để chiếm đoạt của cải. Gây nên 1 trận chiến vô cùng khốc liệt.

![](https://github.com/vinh-ttn/materials/blob/main/simcity/chienloan.gif)

**3) Tống Kim:** chiến trường ác liệt, còn gì tuyệt vời hơn với sự góp mặt của các nhân sĩ võ lâm khắp chốn ao hồ. Bạn có đủ khả năng sống sót không?

![](https://github.com/vinh-ttn/materials/blob/main/simcity/tongkim.gif)

**4) Kéo Xe:** bạn có thể gọi nhân sĩ theo sau cùng đi cho an tâm.

![](https://github.com/vinh-ttn/materials/blob/main/simcity/keoxe.gif)

