SimCityChat = {}

SimCityChat.chatCollection = {

	"Chµ, ®«ng qu¸ nhØ!",
	"ThÌm ¨n kÑo hå l« qu¸ :L",
	"Th»ng An thiÕu tiÒn ch­a tr¶",

	"Kú nµy kĞo héi ®¸nh nã míi ®­îc",
	"Th»ng kia cã tiÒn ®Êy",

	"Trèn ®»ng nµo víi «ng",

	"H«m nay trêi m¸t nhØ",

	"Qu¸n ch¸o lßng ngon qu¸ :)",
	"Th»ng nµo ®¸nh lĞn tao :@",
	"ks = ds",

	"Dang ra! Dang ra!",

	"Kh«ng biÕt quan binh ë ®©u",

	"C« n­¬ng kia xinh thËt",
	"ña g× d¹",

	"Hñ tiÕu ngon nhØ",

	"T­¬ng D­¬ng nµy cã g× vui?",

	"§õng ®Ó tao gÆp :@",

	"T«i bŞ mãc tói råi :L",

	"HÕt tiÒn råi sao giê?",

	"§­êng xa mÖt qu¸",

	"TiÖm vò khİ ë ®©u nhØ ?",

	"Lµm sao luyÖn skill ta?",

	"Nghe nãi D­¬ng Ch©u ®ang m­a",

	"M×nh bŞ bÖnh råi",

	"Thµnh §« L©m An §¹i Lı ta t×m nµng",

	"T×m em gi÷a D­¬ng Ch©u chiÒu m­a",

	"§i ®u ®­a ®i",

	"Con Siªu Quang kia ®Ñp qu¸",

	"Bé HKMP kia vip nhØ",

	"Ğp 6 dßng mµ xŞt hoµi :L",

	"§¸nh hoµi kh«ng th¾ng næi",

	"Mua vâ l©m mËt tŞch ®©y!!!!",

	"Ai b¸n bk NMC ko?",

	"B¸n Thñy Tinh ®©y!!!",

	"ThÌm n­íc mİa qu¸!!!",

	"Nguy hiÓm! Ch¹y lÑ!",

	"T«i kh«ng thÓ h¸t live!",
	"Buån lµm chi em ¬i !",

	"Ai ve chai dĞp ®øt thao nh«m b¸n h«n ?",
	"Xin ®õng h«n t«i",

	"Tao ghim nã n·y giê",

	"Hay lµ m×nh giËt tiÒn nã nhØ",

	"Mïa ®µo n¨m nay ®Ñp thËt",

	"L¹i hÕt tiÒn råi",

	"Nha m«n th¸ng nµy ch­a ph¸t l­¬ng",

	"Qu¸n trµ ¤ Long thËt nh¹t nhÏo",

	"§­êng h«m nay v¾ng c¸c c« n­¬ng nhØ",

	"Nghe nãi LiÔu Thanh Thanh ®ang ë gÇn ®©y",

	"H×nh nh­ HuyÒn Gi¸c §¹i S­ míi võa ®i qua",

	"Cã nªn c­íp nha m«n kh«ng nhØ ?",

	"T×nh h×nh Tèng Kim cã vÎ c¨ng ®©y",

	"Giang hå ®ån r»ng cã kÎ thµnh lËp ¸c Nh©n Cèc",

	"ThÌm b¸nh bao qu¸",

	"§au bông qu¸",

}

SimCityChat.chatCollectionFight = {
	"Ngon nhµo v«!",
	"§­êng nµy do ta më!",
	"Mau ®ãng tiÒn b¶o kª!",
	"Cho xin tİ b¸nh m×!",
	"A th»ng nµy l¸o!",
	"Th»ng nµo d¸m ®¸nh tao!",
	"§øa nµo c¾n lĞn «ng!",
	"Nguy hiÓm! Ch¹y lÑ!",
	"Mµy h¶ nhãc!",
	"§øa nµo d¸m qua ®©y kiÕm ¨n!",
	"Anh em ®©u x«ng lªn !",
	"Hèt nã!"
}	




-- General Helpers
function SimCityChat:getChat()
    return self.chatCollection[random(1, getn(self.chatCollection))]
end
function SimCityChat:getChatFight()
    return self.chatCollectionFight[random(1, getn(self.chatCollectionFight))]
end
