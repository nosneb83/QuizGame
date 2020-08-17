package player

// Player 玩家資料
type Player struct {
	// 狀態
	Ch           chan string // 傳訊息給此玩家用此channel
	ID           int         // 玩家ID
	Name         string      // 暱稱
	Room         int         // 所處房號
	Health       float64     // 血量
	Mainstory    int         //
	Char1unlock  int         //
	Char1relat   int         //
	Char1story   int         //
	Char2unlock  int         //
	Char2relat   int         //
	Char2story   int         //
	Char3unlock  int         //
	Char3relat   int         //
	Char3story   int         //
	Char4unlock  int         //
	Char4relat   int         //
	Char4story   int         //
	Bookmark     int         //
	BookmarkPrem int         //
	Token        int         // 代幣
	Vipstamp     int         //
	Vipexpire    int         //

	// 數據
	Logindays int //
	Pvpwins   int //
	Pvptotal  int //
	Alcorr    int //
	Altotal   int //
	Sccorr    int //
	Sctotal   int //
	Licorr    int //
	Litotal   int //
	Necorr    int //
	Netotal   int //
	Accorr    int //
	Actotal   int //
	Arcorr    int //
	Artotal   int //
	Socorr    int //
	Sototal   int //
	Spcorr    int //
	Sptotal   int //
}
