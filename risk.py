class RiskEngine:
    def validate_trade(self, symbol, volume, price):
        return {"allowed": True, "reason": "Risk check bypassed in init stage"}
