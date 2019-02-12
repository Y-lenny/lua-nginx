--
-- Created by IntelliJ IDEA.
-- User: lennylv
-- Date: 2016/8/29
-- Time: 15:31
-- To change this template use File | Settings | File Templates.
--
local _M = { _VERSION = '0.01' }
local mt = { __index = _M }
local resty_rsa = require "resty.rsa"
local RSA_PUBLIC_KEY = [[
    -----BEGIN RSA PUBLIC KEY-----
    MIGJAoGBAJ9YqFCTlhnmTYNCezMfy7yb7xwAzRinXup1Zl51517rhJq8W0wVwNt+
    mcKwRzisA1SIqPGlhiyDb2RJKc1cCNrVNfj7xxOKCIihkIsTIKXzDfeAqrm0bU80
    BSjgjj6YUKZinUAACPoao8v+QFoRlXlsAy72mY7ipVnJqBd1AOPVAgMBAAE=
    -----END RSA PUBLIC KEY-----
    ]]
local RSA_PRIV_KEY = [[
    -----BEGIN RSA PRIVATE KEY-----
    MIICXAIBAAKBgQCfWKhQk5YZ5k2DQnszH8u8m+8cAM0Yp17qdWZedede64SavFtM
    FcDbfpnCsEc4rANUiKjxpYYsg29kSSnNXAja1TX4+8cTigiIoZCLEyCl8w33gKq5
    tG1PNAUo4I4+mFCmYp1AAAj6GqPL/kBaEZV5bAMu9pmO4qVZyagXdQDj1QIDAQAB
    AoGBAJega3lRFvHKPlP6vPTm+p2c3CiPcppVGXKNCD42f1XJUsNTHKUHxh6XF4U0
    7HC27exQpkJbOZO99g89t3NccmcZPOCCz4aN0LcKv9oVZQz3Avz6aYreSESwLPqy
    AgmJEvuVe/cdwkhjAvIcbwc4rnI3OBRHXmy2h3SmO0Gkx3D5AkEAyvTrrBxDCQeW
    S4oI2pnalHyLi1apDI/Wn76oNKW/dQ36SPcqMLTzGmdfxViUhh19ySV5id8AddbE
    /b72yQLCuwJBAMj97VFPInOwm2SaWm3tw60fbJOXxuWLC6ltEfqAMFcv94ZT/Vpg
    nv93jkF9DLQC/CWHbjZbvtYTlzpevxYL8q8CQHiAKHkcopR2475f61fXJ1coBzYo
    suAZesWHzpjLnDwkm2i9D1ix5vDTVaJ3MF/cnLVTwbChLcXJSVabDi1UrUcCQAmn
    iNq6/mCoPw6aC3X0Uc3jEIgWZktoXmsI/jAWMDw/5ZfiOO06bui+iWrD4vRSoGH9
    G2IpDgWic0Uuf+dDM6kCQF2/UbL6MZKDC4rVeFF3vJh7EScfmfssQ/eVEz637N06
    2pzSvvB4xq6Gt9VwoGVNsn5r/K6AbT+rmewW57Jo7pg=
    -----END RSA PRIVATE KEY-----
    ]]

-- encrypt
function _M.encrypt(self, body)
    local algorithm = "SHA"
    local priv, err = self:new({ private_key = RSA_PRIV_KEY, algorithm = algorithm })
    if not priv then
        ngx.say("new rsa err: ", err)
        return nil, err
    end
    local sig
    sig, err = priv:sign(body)
    if not sig then
        ngx.say("failed to sign:", err)
        return nil, err
    end
    ngx.say("sig length: ", #sig)
    return sig
end

-- decode request
function _M.decode(self, body)
    local pub, err = self:new({ public_key = RSA_PUBLIC_KEY })
    if not pub then
        ngx.say("new rsa err: ", err)
        return nil, err
    end
    local encrypted
    encrypted, err = pub:encrypt(body)
    if not encrypted then
        ngx.say("failed to encrypt: ", err)
        return nil, err
    end
    ngx.say("encrypted length: ", #encrypted)
    return encrypted
end

-- new brush lua class
function _M.new(self)
    return setmetatable(_M, mt)
end

