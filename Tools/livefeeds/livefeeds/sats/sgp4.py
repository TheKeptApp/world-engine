"""SGP4 orbit propagation, near-earth branch (period under 225 minutes), WGS72 constants.

Follows the revised SGP4 of Vallado, Crawford, Hujsak and Kelso, "Revisiting Spacetrack Report #3"
(AIAA 2006-6753), improved operation mode. Deep-space objects (SDP4: GPS, geostationary, Molniya) are
rejected with `DeepSpace`; no naked-eye pass target is one of them. Output is the TEME frame, km and km/s.
"""

import math
from dataclasses import dataclass

TWOPI = 2 * math.pi
X2O3 = 2.0 / 3.0
# WGS72 (the constants the element sets are fitted with).
MU = 398600.8
RE = 6378.135
XKE = 60.0 / math.sqrt(RE ** 3 / MU)
J2 = 0.001082616
J3 = -0.00000253881
J4 = -0.00000165597
J3OJ2 = J3 / J2
VKMPERSEC = RE * XKE / 60.0


class DeepSpace(ValueError):
    pass


class PropagationError(ValueError):
    pass


@dataclass
class Elements:
    """Mean elements as published (TLE/OMM): angles in degrees, mean motion in revolutions per day."""
    norad_id: int
    name: str
    epoch: float          # POSIX seconds (UTC)
    inclination: float
    raan: float
    eccentricity: float
    arg_perigee: float
    mean_anomaly: float
    mean_motion: float
    bstar: float


class Satellite:
    def __init__(self, el: Elements):
        self.el = el
        self.epoch = el.epoch
        self._init()

    def _init(self):
        el = self.el
        d2r = math.pi / 180
        self.ecco = ecco = el.eccentricity
        self.inclo = inclo = el.inclination * d2r
        self.nodeo = el.raan * d2r
        self.argpo = argpo = el.arg_perigee * d2r
        self.mo = mo = el.mean_anomaly * d2r
        no_kozai = el.mean_motion * TWOPI / 1440.0
        self.bstar = bstar = el.bstar
        if not (0 <= ecco < 1):
            raise PropagationError("eccentricity out of range")
        # initl: un-Kozai the mean motion.
        eccsq = ecco * ecco
        omeosq = 1 - eccsq
        rteosq = math.sqrt(omeosq)
        cosio = math.cos(inclo)
        cosio2 = cosio * cosio
        ak = (XKE / no_kozai) ** X2O3
        d1 = 0.75 * J2 * (3 * cosio2 - 1) / (rteosq * omeosq)
        dl = d1 / (ak * ak)
        adel = ak * (1 - dl * dl - dl * (1.0 / 3.0 + 134 * dl * dl / 81.0))
        dl = d1 / (adel * adel)
        self.no = no = no_kozai / (1 + dl)
        ao = (XKE / no) ** X2O3
        sinio = math.sin(inclo)
        po = ao * omeosq
        con42 = 1 - 5 * cosio2
        self.con41 = con41 = -con42 - cosio2 - cosio2
        posq = po * po
        rp = ao * (1 - ecco)
        if TWOPI / no >= 225.0:
            raise DeepSpace("period of %.0f min needs SDP4 (deep space), not supported" % (TWOPI / no))
        ss = 78.0 / RE + 1
        qzms2t = ((120.0 - 78.0) / RE) ** 4
        self.isimp = 1 if rp < (220.0 / RE + 1) else 0
        sfour, qzms24 = ss, qzms2t
        perige = (rp - 1) * RE
        if perige < 156:
            sfour = perige - 78
            if perige < 98:
                sfour = 20
            qzms24 = ((120 - sfour) / RE) ** 4
            sfour = sfour / RE + 1
        pinvsq = 1 / posq
        tsi = 1 / (ao - sfour)
        self.eta = eta = ao * ecco * tsi
        etasq = eta * eta
        eeta = ecco * eta
        psisq = abs(1 - etasq)
        coef = qzms24 * tsi ** 4
        coef1 = coef / psisq ** 3.5
        cc2 = coef1 * no * (ao * (1 + 1.5 * etasq + eeta * (4 + etasq))
                            + 0.375 * J2 * tsi / psisq * con41 * (8 + 3 * etasq * (8 + etasq)))
        self.cc1 = cc1 = bstar * cc2
        cc3 = -2 * coef * tsi * J3OJ2 * no * sinio / ecco if ecco > 1e-4 else 0.0
        self.x1mth2 = x1mth2 = 1 - cosio2
        self.cc4 = 2 * no * coef1 * ao * omeosq * (
            eta * (2 + 0.5 * etasq) + ecco * (0.5 + 2 * etasq)
            - J2 * tsi / (ao * psisq) * (-3 * con41 * (1 - 2 * eeta + etasq * (1.5 - 0.5 * eeta))
                                        + 0.75 * x1mth2 * (2 * etasq - eeta * (1 + etasq)) * math.cos(2 * argpo)))
        self.cc5 = 2 * coef1 * ao * omeosq * (1 + 2.75 * (etasq + eeta) + eeta * etasq)
        cosio4 = cosio2 * cosio2
        temp1 = 1.5 * J2 * pinvsq * no
        temp2 = 0.5 * temp1 * J2 * pinvsq
        temp3 = -0.46875 * J4 * pinvsq * pinvsq * no
        self.mdot = no + 0.5 * temp1 * rteosq * con41 + 0.0625 * temp2 * rteosq * (13 - 78 * cosio2 + 137 * cosio4)
        self.argpdot = (-0.5 * temp1 * con42 + 0.0625 * temp2 * (7 - 114 * cosio2 + 395 * cosio4)
                        + temp3 * (3 - 36 * cosio2 + 49 * cosio4))
        xhdot1 = -temp1 * cosio
        self.nodedot = xhdot1 + (0.5 * temp2 * (4 - 19 * cosio2) + 2 * temp3 * (3 - 7 * cosio2)) * cosio
        self.omgcof = bstar * cc3 * math.cos(argpo)
        self.xmcof = -X2O3 * coef * bstar / eeta if ecco > 1e-4 else 0.0
        self.nodecf = 3.5 * omeosq * xhdot1 * cc1
        self.t2cof = 1.5 * cc1
        den = 1 + cosio if abs(cosio + 1) > 1.5e-12 else 1.5e-12
        self.xlcof = -0.25 * J3OJ2 * sinio * (3 + 5 * cosio) / den
        self.aycof = -0.5 * J3OJ2 * sinio
        self.delmo = (1 + eta * math.cos(mo)) ** 3
        self.sinmao = math.sin(mo)
        self.x7thm1 = 7 * cosio2 - 1
        if self.isimp != 1:
            cc1sq = cc1 * cc1
            self.d2 = d2 = 4 * ao * tsi * cc1sq
            temp = d2 * tsi * cc1 / 3
            self.d3 = d3 = (17 * ao + sfour) * temp
            self.d4 = d4 = 0.5 * temp * ao * tsi * (221 * ao + 31 * sfour) * cc1
            self.t3cof = d2 + 2 * cc1sq
            self.t4cof = 0.25 * (3 * d3 + cc1 * (12 * d2 + 10 * cc1sq))
            self.t5cof = 0.2 * (3 * d4 + 12 * cc1 * d3 + 6 * d2 * d2 + 15 * cc1sq * (2 * d2 + cc1sq))

    def propagate_minutes(self, t: float):
        """(r, v) in TEME, km and km/s, `t` minutes after the element epoch."""
        xmdf = self.mo + self.mdot * t
        argpdf = self.argpo + self.argpdot * t
        nodedf = self.nodeo + self.nodedot * t
        argpm, mm = argpdf, xmdf
        t2 = t * t
        nodem = nodedf + self.nodecf * t2
        tempa = 1 - self.cc1 * t
        tempe = self.bstar * self.cc4 * t
        templ = self.t2cof * t2
        if self.isimp != 1:
            delomg = self.omgcof * t
            delm = self.xmcof * ((1 + self.eta * math.cos(xmdf)) ** 3 - self.delmo)
            temp = delomg + delm
            mm = xmdf + temp
            argpm = argpdf - temp
            t3 = t2 * t
            t4 = t3 * t
            tempa = tempa - self.d2 * t2 - self.d3 * t3 - self.d4 * t4
            tempe = tempe + self.bstar * self.cc5 * (math.sin(mm) - self.sinmao)
            templ = templ + self.t3cof * t3 + t4 * (self.t4cof + t * self.t5cof)
        nm, em, inclm = self.no, self.ecco, self.inclo
        if nm <= 0:
            raise PropagationError("mean motion not positive")
        am = (XKE / nm) ** X2O3 * tempa * tempa
        nm = XKE / am ** 1.5
        em = em - tempe
        if em >= 1 or em < -0.001:
            raise PropagationError("eccentricity out of range during propagation")
        em = max(em, 1e-6)
        mm = mm + self.no * templ
        xlm = mm + argpm + nodem
        nodem = math.fmod(nodem, TWOPI)
        argpm = math.fmod(argpm, TWOPI)
        xlm = math.fmod(xlm, TWOPI)
        mm = math.fmod(xlm - argpm - nodem, TWOPI)
        sinip, cosip = math.sin(inclm), math.cos(inclm)
        axnl = em * math.cos(argpm)
        temp = 1 / (am * (1 - em * em))
        aynl = em * math.sin(argpm) + temp * self.aycof
        xl = mm + argpm + nodem + temp * self.xlcof * axnl
        u = math.fmod(xl - nodem, TWOPI)
        eo1 = u
        tem5 = 9999.9
        ktr = 1
        while abs(tem5) >= 1e-12 and ktr <= 10:
            sineo1, coseo1 = math.sin(eo1), math.cos(eo1)
            tem5 = 1 - coseo1 * axnl - sineo1 * aynl
            tem5 = (u - aynl * coseo1 + axnl * sineo1 - eo1) / tem5
            if abs(tem5) >= 0.95:
                tem5 = 0.95 if tem5 > 0 else -0.95
            eo1 += tem5
            ktr += 1
        sineo1, coseo1 = math.sin(eo1), math.cos(eo1)
        ecose = axnl * coseo1 + aynl * sineo1
        esine = axnl * sineo1 - aynl * coseo1
        el2 = axnl * axnl + aynl * aynl
        pl = am * (1 - el2)
        if pl < 0:
            raise PropagationError("semi-latus rectum negative")
        rl = am * (1 - ecose)
        rdotl = math.sqrt(am) * esine / rl
        rvdotl = math.sqrt(pl) / rl
        betal = math.sqrt(1 - el2)
        temp = esine / (1 + betal)
        sinu = am / rl * (sineo1 - aynl - axnl * temp)
        cosu = am / rl * (coseo1 - axnl + aynl * temp)
        su = math.atan2(sinu, cosu)
        sin2u = (cosu + cosu) * sinu
        cos2u = 1 - 2 * sinu * sinu
        temp = 1 / pl
        temp1 = 0.5 * J2 * temp
        temp2 = temp1 * temp
        mrt = rl * (1 - 1.5 * temp2 * betal * self.con41) + 0.5 * temp1 * self.x1mth2 * cos2u
        su = su - 0.25 * temp2 * self.x7thm1 * sin2u
        xnode = nodem + 1.5 * temp2 * cosip * sin2u
        xinc = inclm + 1.5 * temp2 * cosip * sinip * cos2u
        mvt = rdotl - nm * temp1 * self.x1mth2 * sin2u / XKE
        rvdot = rvdotl + nm * temp1 * (self.x1mth2 * cos2u + 1.5 * self.con41) / XKE
        sinsu, cossu = math.sin(su), math.cos(su)
        snod, cnod = math.sin(xnode), math.cos(xnode)
        sini, cosi = math.sin(xinc), math.cos(xinc)
        xmx, xmy = -snod * cosi, cnod * cosi
        ux, uy, uz = xmx * sinsu + cnod * cossu, xmy * sinsu + snod * cossu, sini * sinsu
        vx, vy, vz = xmx * cossu - cnod * sinsu, xmy * cossu - snod * sinsu, sini * cossu
        if mrt < 1:
            raise PropagationError("satellite has decayed")
        r = (mrt * ux * RE, mrt * uy * RE, mrt * uz * RE)
        v = ((mvt * ux + rvdot * vx) * VKMPERSEC, (mvt * uy + rvdot * vy) * VKMPERSEC,
             (mvt * uz + rvdot * vz) * VKMPERSEC)
        return r, v

    def propagate(self, posix: float):
        return self.propagate_minutes((posix - self.epoch) / 60.0)
