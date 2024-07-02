# SimCity Mod for JX1 Linux

—vinhsmoke—

**Chú ý:** Game 1ClickVMFull (xem [post của hội quán](https://www.facebook.com/groups/volamquan/permalink/1389335278442327/) hoặc [Hướng Dẫn - Võ Lâm 1ClickVMFull](https://docs.google.com/document/d/1BUtlCyJdIg-Dc15EZLYU7dMAcGA4wzcZDMBrM3dRpcc/edit?usp=sharing)) đã có sẵn SimCity 5.0, không phải cài theo hướng dẫn của tài liệu này. Nhưng nên liên tục update qua app để có phiên bản Simcity mới nhất.



## A. Giới thiệu tính năng

Có thể sử dụng trên cả 2 bản server Linux 6 và 8

**1) Thành thị:** thành thị sẽ trở nên nhộn nhịp với các gian hàng và các nhân sĩ võ lâm đi lại. Các nhân sĩ có thể đánh nhau bất cứ lúc nào. Ngoài ra bạn có thể gọi thêm quan binh tuần tra (nhưng cũng vô ích) hoặc các quái khách trên cõi giang hồ.

**2) Chiến loạn:** khi mở, nhân sĩ ở Tương Dương và Biện Kinh sẽ trực tiếp tiến vào thành để chiếm đoạt của cải. Gây nên 1 trận chiến vô cùng khốc liệt.

**3) Tống Kim:** chiến trường ác liệt, còn gì tuyệt vời hơn với sự góp mặt của các nhân sĩ võ lâm khắp chốn ao hồ. Bạn có đủ khả năng sống sót không?

**4) Kéo Xe:** bạn có thể gọi nhân sĩ theo sau cùng đi cho an tâm.


## B. Hướng dẫn cài đặt thủ công Thành Thị, Chiến Loạn và Kéo Xe

Chú ý: 

- khi sửa và lưu bất kỳ file nào trên server thì cần lưu dưới dạng windows-1252 encode chứ không phải unicode utf-8. Nhớ xem kỹ editor của WinSCP coi cài đặt đúng chưa trước khi lưu file.
- nên tạo backup autoexec.lua trước khi bắt đầu chỉnh sửa để có gì còn phục hồi lại được 
- chỉ cần chỉnh sửa và cài trên server. Không cần đồng bộ hay cài gì bên phía client.

1\) Download file [Simcity](https://github.com/vinh-ttn/simcity/archive/refs/heads/main.tar.gz) về, giải nén và chép toàn bộ vào thư mục gốc của server

2\) Mở file **server1/script/global/autoexec.lua** trên server và tìm đến dòng:

`function main()`

thêm vào trước đó dòng này:

`Include("\\script\\global\\vinh\\main.lua")`

và sau đó dòng này:

`add_npc_vinh()`

(Mục đích là để include file và gọi hàm add_npc_vinh.) 

Sau khi chỉnh xong thì tổng thể chổ đó của file nó nhìn giống như vầy:

```
Include("\\script\\global\\vinh\\main.lua")

function main()
    add_npc_vinh()
```
    

Có thể xem file autoexec tham khảo trong drive để làm mẫu (nhưng đừng dùng trực tiếp vì mỗi server mà AE share mỗi khác)

3\) Xong. Khởi động server và tìm đến gần hiệu thuốc Tương Dương:

     \* gặp Triệu Mẫn để sử dụng simcity

     \* gặp Vô Kỵ để điều khiển kéo xe (+ nhận lệnh bài kéo xe\*)


## C. Hướng dẫn cài đặt thủ công Tống Kim (Bảo vệ nguyên soái)

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


## D. Thông tin thêm

### Kéo xe NPC

    1) Nếu muốn tạo lệnh bài gọi xe nhanh đem theo bên mình (thay vì NPC Vô Kỵ) thì vào <https://jxoffline.github.io/jxtools/shopbuilder.d/>  để tạo thêm 1 vật phẩm với đường link tới file script

        `\script\global\vinh\simcity\controllers\main.lua`   

    2) Nếu muốn thay đổi danh sách theo sau (hoặc tạo riêng cho mình) thì sửa file

        `\script\global\vinh\simcity\plugins\pkeoxe.lua`


### NPC quá mạnh 

****![](https://lh7-us.googleusercontent.com/docsz/AD_4nXctDkLIw67xDMciom4lw9DzdbTlcLTFPF0s57aM2Y4_AsVgtZUKGvjm68E4HK9dka3f3LTKdGHumHDsom9GgLVrWVQoaXZGlLCftrT9FNMKJEgl_0WBaUnjFO5fb4__zu2iQ83PfpFS7MEYFA-AESd1RuNg?key=my0UP0YCEuAhRT8eOcMeRw)****&#x20;



## E. Thay đổi giữa các phiên bản

|                          | Ngày       | Thay đổi                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| ------------------------ | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1.0 SimCity & Kéo Xe** | 09/2023    | (Mới) Mở **gian hàng và dân chúng đi lại** ở Tương Dương. (Thêm) KéoXe                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **2.0 Chiến Loạn**       | 10/2023    | (Mới) **Chiến loạn** - tấn công thành thị Biện Kinh (trong ra) và Tương Dương (ngoài vô)(Mới) Quan binh tuần tra theo hàng ngũ(Mới) Tình trạng kéo xe xuất hiện(Sửa) Thêm vào các thành khác:* Biện Kinh, Phượng Tường, Đại Lý - đóng góp: [Duy Ngô](https://www.facebook.com/groups/800085930700601/user/61551322996134/?__cft__\[0]=AZV_RO8NdTMsDVO11CipaZsHNtjqKQQsQJebqI3krEgYfekv-O3hYkpBHZRvMGotp0F36toUiCvyWK-zKBZgXLRNWp2TxuffMYJiIinfpCuSZemoGktyHngQc9mm-ATN2i9PHp5BCOw8JbQZpIOk_huce_tfE_AYsEECbgtGCdZE3JuZIH-U7QkJA_p_Os8k06j7vUapty9Q3UE48J5HjouV&__tn__=R]-R) <br>* Lâm An - đóng góp: [Huy Nguyen](https://www.facebook.com/groups/800085930700601/user/100004608648396/?__cft__\[0]=AZV_RO8NdTMsDVO11CipaZsHNtjqKQQsQJebqI3krEgYfekv-O3hYkpBHZRvMGotp0F36toUiCvyWK-zKBZgXLRNWp2TxuffMYJiIinfpCuSZemoGktyHngQc9mm-ATN2i9PHp5BCOw8JbQZpIOk_huce_tfE_AYsEECbgtGCdZE3JuZIH-U7QkJA_p_Os8k06j7vUapty9Q3UE48J5HjouV&__tn__=R]-R) |
| **3.0 Tống Kim**         | 10/2023    | (Mới) **Tống Kim**:* thêm map bảo vệ nguyên soái<br>* tính điểm và thông báo bảng xếp hạng<br>* thêm Vô Kỵ phe Tống, Triệu Mẫn phe Kim(Sửa) Thêm vào các thành khác:* Thành Đô, Dương Châu<br>* Chỉnh sửa các thành hiện tại để tối ưu đường đi                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| **4.0**                  | 10/2023    | (Mới) **Thay đổi toàn bộ hệ thống code** để tiện đường thêm thắt sau này (gọi là plugin). Gọp kéo xe thành 1 plugin nhỏ của SimCity thay vì 2 mod khác nhau.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| **5.0 RC1**              | 12/11/2013 | (Mới) **nhân sĩ võ lâm có hình người chơi**, bao gồm vũ khí hoàng kim và chỉ sử dụng skill người chơi(Sửa) danh sách tên lạ võ lâm(Sửa) danh sách đối thoại võ lâm(Sửa) chia cấp độ nhân sĩ theo máu cho chính xác (sơ cấp máu vẫn còn quá nhiều)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| **?**                    | ?          | (Mới) thêm công thành trong Thất Thành Đại Chiến(Sửa) máu lại cho hợp lý vì không phải ai cũng xài đồ siêu nhân =))(Sửa) thêm người chơi vào danh sách Bảng Xếp Hạng trong Tống Kim                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
