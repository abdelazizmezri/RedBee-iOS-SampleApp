struct QRCodeURLParameters {
    var env: String?
    var cu: String?
    var bu: String?
    var source: String?
    var sessionToken: String?
    
    init(
        env: String? = nil,
        cu: String? = nil,
        bu: String? = nil,
        source: String? = nil,
        sessionToken: String? = nil
    ) {
        self.env = env
        self.cu = cu
        self.bu = bu
        self.source = source
        self.sessionToken = sessionToken
    }
}
