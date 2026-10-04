package psychomatrix

// Turkish ("tr") counterparts of the interpretive tables in descriptions.go.
// Keys and band order mirror the English tables exactly; the completeness
// test in descriptions_test.go fails if an English entry has no Turkish one.

var cellTitlesTR = map[int]string{
	1: "Karakter",
	2: "Enerji",
	3: "İlgi ve Kavrayış",
	4: "Sağlık",
	5: "Mantık ve Sezgi",
	6: "Beceri ve Emek",
	7: "Şans",
	8: "Görev Bilinci",
	9: "Hafıza ve Zekâ",
}

// cellBandsTR[digit] = [absent, single, double, triple, abundant].
var cellBandsTR = map[int][5]string{
	1: {
		"Hiç 1 yok: yumuşak, uyumlu bir irade. Karakterini başkaları aracılığıyla şekillendirir, ısrar etmek yerine geri adım atmayı seçersin.",
		"Bir tane 1: esnek bir benmerkezci — kendi çıkarını gözetirsin ama eğilmeyi de bilirsin; kendi ihtiyaçlarını başkalarınınkiyle tartarsın.",
		"İki tane 1: dengeli, oturmuş bir karakter. Ne istediğini bilirsin ama bunu kimseye dayatmazsın.",
		"Üç tane 1: istikrarlı, sakin bir irade. Uyumlusun ama önemli anlarda sapasağlam durursun.",
		"Dört veya daha fazla 1: güçlü, baskın bir irade. Doğuştan bir lidersin; inatçı olabilir, kolay kolay geri adım atmazsın.",
	},
	2: {
		"Hiç 2 yok: doğuştan gelen biyoenerjin çok düşük; enerjini birikimden değil, özenden, temastan ve iyi alışkanlıklardan beslenerek yenilersin.",
		"Bir tane 2: mütevazı enerji rezervleri. Aldığın kadarını verirsin ve başkaları için kendini tüketmekten hoşlanmazsın.",
		"İki tane 2: sağlıklı bir biyoenerji ve başkalarını sezme yeteneği — doğal bir empatsın, bazen de bir şifacı.",
		"Üç tane 2: güçlü bir sezgiyle birleşen bol enerji; başkalarına yardım etmeye ya da şifa vermeye doğru içten bir çekim hissedersin.",
		"Dört veya daha fazla 2: güçlü, manyetik bir enerji. Çok şey verebilirsin ama tükenmemek için kendini korumayı unutma.",
	},
	3: {
		"Hiç 3 yok: kesin bilimlere pek ilgi duymazsın; teori yerine sezgine, düzene ve titizliğe yaslanırsın.",
		"Bir tane 3: ortalama bir merak — ilgi alanların ruh haline ve koşullara göre gelir gider.",
		"İki tane 3: uygulamayı seçtiğinde bilime, teknolojiye ya da analize gerçek bir yatkınlığın var.",
		"Üç tane 3: güçlü bir bilimsel ve analitik yetenek; kesinlik ve derinlemesine çalışma sana doğal gelir.",
		"Dört veya daha fazla 3: olağanüstü bir bilişsel güç — dağılmamak için en iyisi onu tek bir alana odaklamak.",
	},
	4: {
		"Hiç 4 yok: daha narin bir bünye; sağlığın, özellikle ileriki yaşlarda, düzenli özen ve dinlenmeyle güçlenir.",
		"Bir tane 4: genel olarak sağlam bir sağlık ve zorlanmaya karşı ortalama bir dayanıklılık.",
		"İki tane 4: sağlam bir bünye ve iyi bir fiziksel dayanıklılık.",
		"Üç tane 4: güçlü bir canlılık ve dayanıklılık; çabuk toparlanır, geç yorulursun.",
		"Dört veya daha fazla 4: çok güçlü fiziksel rezervler ve atletik, dayanıklı bir yapı.",
	},
	5: {
		"Hiç 5 yok: daha çok deneyerek ve yanılarak öğrenirsin; çoğu zaman aynı keşfi birden fazla kez yaparsın.",
		"Bir tane 5: gelişmekte olan bir sezgi; aklın sağlam çalışır ama kendinden şüphe etmen sık görülür.",
		"İki tane 5: iyi gelişmiş bir mantık ve sezgi — nadiren yanlış yola saparsın, durumları net okursun.",
		"Üç tane 5: neredeyse durugörü düzeyinde bir sezgi ve keskin bir akıl yürütme.",
		"Dört veya daha fazla 5: güçlü bir iç pusula; sonuçları önceden sezer, önemli kararlarda pek yanılmazsın.",
	},
	6: {
		"Hiç 6 yok: el işçiliğine doğal bir çekimin yok; zihinsel işleri tercih edersin ve el becerilerini sonradan öğrenmen gerekebilir.",
		"Bir tane 6: gerektiğinde ellerinle iş çıkarabilirsin ama zanaat ilk aşkın değil.",
		"İki tane 6: fiziksel, el emeğine dayalı ya da zanaat işlerine gerçek bir yatkınlık — üretmekten ve inşa etmekten keyif alırsın.",
		"Üç tane 6: güçlü bir pratik beceri ve ayakları yere basan, üretken emeğe gerçek bir sevgi.",
		"Dört veya daha fazla 6: olağanüstü bir üreticisin; ağır fiziksel ya da teknik işlerde parlarsın — bunu dinlenmeyle dengelemeyi unutma.",
	},
	7: {
		"Hiç 7 yok: şans sana verilmez, onu sen kazanırsın; talihini tesadüfle değil, emek ve azimle örersin.",
		"Bir tane 7: hafif bir şans damarı ve sen onu besledikçe büyüyen gizli bir yetenek.",
		"İki tane 7: belirgin bir talih ve açık bir yaratıcı ya da sanatsal yetenek.",
		"Üç tane 7: güçlü bir şans ve yetenek; fırsatlar sanki seni bulur, yetenekler sana kolayca gelir.",
		"Dört veya daha fazla 7: belirgin, neredeyse koruyucu bir talih — sorumlulukla kullanılmayı bekleyen büyük bir yetenek.",
	},
	8: {
		"Hiç 8 yok: gelişmekte olan bir görev bilinci; sorumluluk ve dakiklik zamanla kazandığın niteliklerdir.",
		"Bir tane 8: makul bir görev bilinci — yükümlülüklerini, özellikle kendi seçtiklerini, yerine getirirsin.",
		"İki tane 8: güçlü, güvenilir bir sorumluluk duygusu ve başkalarına karşı içten bir özen.",
		"Üç tane 8: derin, kimi zaman kendini feda edecek kadar güçlü bir görev ve hizmet duygusu.",
		"Dört veya daha fazla 8: olağanüstü, her şeyi kaplayan bir yükümlülük duygusu; aynı özeni kendine de göstermeyi unutma.",
	},
	9: {
		"Hiç 9 yok: hafıza ve soyut düşünme çaba ister; tekrar ve düzenli notlar sana çok iyi gelir.",
		"Bir tane 9: ortalama bir hafıza ve zekâ — günlük hayat için yeterli, bilinçli pratikle keskinleşir.",
		"İki tane 9: iyi bir zihin ve güvenilir bir hafıza; fikirleri kolayca kavrar ve akılda tutarsın.",
		"Üç tane 9: keskin bir zekâ ve güçlü bir hafıza; öğrenmek sana hızlı gelir.",
		"Dört veya daha fazla 9: parlak ve kalıcı bir zihin — zorlu entelektüel işlere yatkınsın ama daha yavaş düşünenlere karşı çabuk sabırsızlanabilirsin.",
	},
}

var lineTitlesTR = map[string]string{
	"row_147":  "Amaç Duygusu",
	"row_258":  "Aile",
	"row_369":  "İstikrar",
	"col_123":  "Özsaygı",
	"col_456":  "Gündelik / Maddi",
	"col_789":  "Yetenek",
	"diag_159": "Maneviyat",
	"diag_357": "Mizaç",
}

// lineBandsTR[key] = [weak, balanced, strong].
var lineBandsTR = map[string][3]string{
	"row_147": {
		"Zayıf amaç duygusu: hedeflerin kolayca değişir ve bir işi sonuna kadar götürmek zor olabilir.",
		"Dengeli kararlılık: hedefler koyar, onların peşinden istikrarlı ve gerçekçi bir azimle gidersin.",
		"Çok güçlü amaç duygusu: istediğine doğru durmaksızın ilerleyen, hedef odaklı ve tutkulu bir doğa.",
	},
	"row_258": {
		"Düşük aile dürtüsü: önce bağımsızlık gelir; birliktelik ve ev hayatı bilinçli bir çaba ister.",
		"Dengeli aile yatkınlığı: yakın bağlara değer verirsin ve sıcak, istikrarlı bir yuva kurabilirsin.",
		"Güçlü aile yönelimi: sevdiklerine ve yuvana derinden bağlısın, bazen kendi pahasına.",
	},
	"row_369": {
		"Düşük istikrar: huzursuz ve değişkensin; rutinden çok yenilikle beslenirsin.",
		"Dengeli istikrar: katı olmadan ayakları yere basan ve tutarlı bir yapı.",
		"Yüksek istikrar: çok oturmuş ve güvenilirsin; zaman zaman gerekli değişime bile direnebilirsin.",
	},
	"col_123": {
		"Kırılgan özsaygı: özgüvenin büyük ölçüde dışarıdan gelen onaya bağlı.",
		"Sağlıklı özsaygı: kendi değerine dair istikrarlı ve gerçekçi bir his.",
		"Güçlü özsaygı: belirgin bir kendinden eminlik; dikkat etmezsen gurura dönüşebilir.",
	},
	"col_456": {
		"Düşük maddi odak: pratik, gündelik işler sana bir çağrıdan çok angarya gibi gelir.",
		"Dengeli pratiklik: günlük işlerde ve kaynakları yönetmede yetkin ve verimlisin.",
		"Güçlü maddi dürtü: pratik, dünyevi işlerde son derece yetenekli ve çalışkansın.",
	},
	"col_789": {
		"Gizli yetenek: armağanların var ama gün yüzüne çıkmaları için bilinçli bir emek gerekiyor.",
		"Dengeli yetenek: geliştirebileceğin ve güvenebileceğin belirgin yetenekler.",
		"Bol yetenek: kendine bir çıkış bulduğunda filizlenen, güçlü ve çok yönlü armağanlar.",
	},
	"diag_159": {
		"Düşük maneviyat: metafiziğe pek çekim duymayan, pratik ve maddi bir bakış açısı.",
		"Dengeli maneviyat: ayakların yerden kesilmeden anlama ve iç dünyaya açıksın.",
		"Güçlü maneviyat: seçimlerine yön veren, derinden hissedilen bir iç ve metafizik yaşam.",
	},
	"diag_357": {
		"Serin mizaç: ölçülü ve dengelisin; tutkuda da çatışmada da geç alevlenirsin.",
		"Dengeli mizaç: değişken olmadan sıcak ve duyarlı.",
		"Ateşli mizaç: sağlıklı çıkış yolları isteyen yoğun, tutkulu bir enerji.",
	},
}
