package numerology

// Turkish ("tr") counterparts of the description tables in descriptions.go.
// Keys mirror the English tables exactly; descriptions_test.go fails if an
// English entry has no Turkish one.

var masterDescTR = map[int]string{
	11: "Usta Sayı 11: ruhani haberci; ilhamın sezgiyle buluştuğu yer. Kendi hakikatini yaşadıkça başkalarının yolunu da aydınlatırsın.",
	22: "Usta Sayı 22: usta inşacı; büyük vizyonları elle tutulur gerçekliğe dönüştürürsün. Ayakları yere basan bir idealizm.",
	33: "Usta Sayı 33: usta öğretmen; şefkat ve yaratıcı iletişimle karşılıksız hizmet.",
}

var descTablesTR = map[string]map[int]string{
	"life_path":      lifePathDescTR,
	"expression":     expressionDescTR,
	"soul_urge":      soulUrgeDescTR,
	"personality":    personalityDescTR,
	"maturity":       maturityDescTR,
	"birthday":       birthdayDescTR,
	"personal_year":  personalYearDescTR,
	"personal_month": personalMonthDescTR,
	"personal_day":   personalDayDescTR,
}

var lifePathDescTR = map[int]string{
	1: "Öncü. Bağımsız bir lider; yeni yollar açmak ve kendi ayakların üzerinde durmak için buradasın.",
	2: "Arabulucu. Hassas bir işbirlikçi; uyum getirmek, derinden dinlemek ve insanları bir araya getirmek için buradasın.",
	3: "İletişimci. Yaratıcı bir ifade ustası; sözlerle ve sanatla neşe ve ilham saçmak için buradasın.",
	4: "İnşacı. Disiplinli bir zanaatkâr; kalıcı yapılar ve güvenilir sistemler kurmak için buradasın.",
	5: "Maceracı. Özgürlük peşinde bir ruh; deneyimlemek, değişmek ve köhnemiş kalıpları kırmak için buradasın.",
	6: "Koruyucu. Kalbiyle yaşayan bir besleyici; ailene ve topluluğuna şifa, güzellik ve koruma getirmek için buradasın.",
	7: "Arayıcı. İçine dönük bir mistik; araştırmak, sorgulamak ve gizli hakikatleri gün yüzüne çıkarmak için buradasın.",
	8: "Güç Merkezi. Maddi dünyanın ustası; bereket inşa etmek, topluluklara liderlik etmek ve hırsı dürüstlükle dengelemek için buradasın.",
	9: "İnsancıl. Yaşlı bir ruh; bütüne hizmet etmek, geçmişi bırakmak ve sınırsızca sevmek için buradasın.",
}

var expressionDescTR = map[int]string{
	1: "Yeteneklerin inisiyatif ve özgün bir liderlik olarak ortaya çıkar.",
	2: "Yeteneklerin ortaklık, incelik ve zarif bir işbirliği yoluyla ortaya çıkar.",
	3: "Yeteneklerin yaratıcı ifade olarak ortaya çıkar — yazı, sanat, sahne ve sosyal çekicilik.",
	4: "Yeteneklerin yöntemli çalışma, düzen ve somut sonuçlar yoluyla ortaya çıkar.",
	5: "Yeteneklerin çok yönlü iletişim, yolculuklar ve macera ruhu olarak ortaya çıkar.",
	6: "Yeteneklerin besleme, şifa verme, öğretme ve güzellik yaratma yoluyla ortaya çıkar.",
	7: "Yeteneklerin derin bilgi, analiz, sezgi ve sessiz bir otorite olarak ortaya çıkar.",
	8: "Yeteneklerin yönetme gücü, strateji ve maddi başarı yoluyla ortaya çıkar.",
	9: "Yeteneklerin insanlığa hizmet, sanat ve geniş bir kültürel vizyon olarak ortaya çıkar.",
}

var soulUrgeDescTR = map[int]string{
	1: "Ruhun özgürce kendi yolunu çizmeye ve özgün bir iz bırakmaya özlem duyar.",
	2: "Ruhun uyuma, yakınlığa ve destekleyici bir birlikteliğe özlem duyar.",
	3: "Ruhun yaratmaya, sahnede parlamaya ve takdir görmeye özlem duyar.",
	4: "Ruhun istikrara, düzene ve gerçekten sana ait bir yere özlem duyar.",
	5: "Ruhun özgürlüğe, yeniliğe ve önündeki açık yollara özlem duyar.",
	6: "Ruhun beslemeye, güzelleştirmeye ve sevgiyle kuşatılmaya özlem duyar.",
	7: "Ruhun yalnızlığa, derin araştırmaya ve gizemi doğrudan deneyimlemeye özlem duyar.",
	8: "Ruhun maddi dünyada ustalığa ve mükemmelliğinin takdir edilmesine özlem duyar.",
	9: "Ruhun herkesi sevmeye ve daha büyük bir bütüne katkıda bulunmaya özlem duyar.",
}

var personalityDescTR = map[int]string{
	1: "Dışarıdan kendinden emin ve kendi yolunu çizen biri olarak görünürsün.",
	2: "Dışarıdan nazik, ilgili ve yanında rahat edilen biri olarak görünürsün.",
	3: "Dışarıdan ışıltılı, esprili ve sosyal açıdan sıcak biri olarak görünürsün.",
	4: "Dışarıdan sağlam, güvenilir ve yöntemli biri olarak görünürsün.",
	5: "Dışarıdan heyecan verici, manyetik ve biraz da öngörülemez biri olarak görünürsün.",
	6: "Dışarıdan sıcak, kucaklayıcı ve ebeveyn şefkatinde biri olarak görünürsün.",
	7: "Dışarıdan içe dönük, gizemli ve derin biri olarak görünürsün.",
	8: "Dışarıdan etkileyici, yetkin ve otorite sahibi biri olarak görünürsün.",
	9: "Dışarıdan şefkatli, görmüş geçirmiş ve sessizce bilge biri olarak görünürsün.",
}

var maturityDescTR = map[int]string{
	1: "Olgunluk sana kendi yolunu bağımsızca çizme gücü getirir.",
	2: "Olgunluk sana daha derin bir birliktelik ve iç huzur getirir.",
	3: "Olgunluk sana incelmiş, rafine bir yaratıcı ifade getirir.",
	4: "Olgunluk sana usta işi bir zanaat ve kalıcı bir miras getirir.",
	5: "Olgunluk sana ne zaman yola çıkıp ne zaman kök salacağını bilen bir bilgelik getirir.",
	6: "Olgunluk sana sevgide, ailede ve güzellikte ustalık getirir.",
	7: "Olgunluk sana derin bir bilgelik ve içsel bir kesinlik getirir.",
	8: "Olgunluk sana egoya değil, hizmete adanmış bir güç getirir.",
	9: "Olgunluk sana evrensel bir şefkat ve zarif vedalar getirir.",
}

var birthdayDescTR = map[int]string{
	1: "Öncü kıvılcımı.", 2: "Diplomatik dokunuş.", 3: "Yaratıcı neşe.",
	4: "Sağlam temel.", 5: "Durmak bilmeyen merak.", 6: "Şefkatli kalp.",
	7: "Arayıcı zihin.", 8: "Yönetici dürtüsü.", 9: "Şefkatli vizyon.",
}

var personalYearDescTR = map[int]string{
	1: "Taze başlangıçların ve cesur atılımların yılı.",
	2: "Birlikteliğin, sabrın ve yavaş yavaş olgunlaşmanın yılı.",
	3: "Yaratıcı ifadenin ve neşeli buluşmaların yılı.",
	4: "Emeğin, düzenin ve sağlam temeller atmanın yılı.",
	5: "Değişimin, yolculukların ve rutinden kopmanın yılı.",
	6: "Ailenin, yuvanın ve sorumluluğun yılı.",
	7: "Tefekkürün, araştırmanın ve içsel büyümenin yılı.",
	8: "Maddi başarının ve ektiklerini biçmenin yılı.",
	9: "Tamamlanmanın, bırakmanın ve insanlığa cömertçe vermenin yılı.",
}

var personalMonthDescTR = map[int]string{
	1: "Başlat.", 2: "İşbirliği yap.", 3: "Kendini ifade et.", 4: "İnşa et.", 5: "Değiş.",
	6: "Özen göster.", 7: "İçine dön.", 8: "Başar.", 9: "Bırak.",
}

var personalDayDescTR = map[int]string{
	1: "Bir şeye başla.", 2: "Bir ilişkini besle.", 3: "Yarat ya da paylaş.",
	4: "Özenle çalış.", 5: "Temponu değiştir.", 6: "Birine özen göster.",
	7: "Dur ve düşün.", 8: "Kontrolü eline al.", 9: "Bir şeyin tamamlanmasına izin ver.",
}
