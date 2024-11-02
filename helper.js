/*
    x = 1       ETH
    y = 2907    USDC
    P = 2486.8
    w = 2012


    To find:
        price_high = 2998.9
        price_low = 1994.2
*/
const k = 10000;

const calculatePh = (Pl, w) => (Pl * (w + k)) / (k - w);
const left = (x, P, Ph) =>
  (x * (Math.sqrt(P) * Math.sqrt(Ph))) / (Math.sqrt(Ph) - Math.sqrt(P));
const right = (y, P, Pl) => y / (Math.sqrt(P) - Math.sqrt(Pl));
const calculateW = (Pl, Ph) => ((Ph - Pl) * k) / (Pl + Ph);

const solveQuadratic = (a, b, p, y) => {
    console.log(`a: ${a} b: ${b}`);

    const A = b;
    const B = Math.sqrt(a) * y - Math.sqrt(a) * b * Math.sqrt(p);
    const C = -Math.sqrt(a) * Math.sqrt(p) * y;

    const discriminant = B*B - 4 * A * C;  
    console.log(`A: ${A} B:${B} C:${C} discr: ${discriminant}`);

    if (discriminant < 0) throw "no solution";
    const z1 = (-B + Math.sqrt(discriminant)) / 2 / A;  
    const z2 = (-B - Math.sqrt(discriminant)) / 2 / A;  

    console.log(`z1: ${z1} z2: ${z2}`);

    if (z1 <= 0 && z2 <= 0) throw "all solutions negative";
    return z1 > 0 ? z1: z2;
};

x = 1;
y = 2907.47;
price = 2486.8;
w = 2012;
price_high = 2998.9;
price_low = 1994.2;

a = (w + k) / (k - w);

b = x*Math.sqrt(price);


quad = solveQuadratic(a, b, price, y);
Ph = quad**2;
Pl = Ph / a;

console.log("Pl:", Pl);
console.log("Ph:", Ph);

// Pl = calculatePl(w, x, price, y);
// console.log("priceLow: ", Pl);

// Ph = calculatePh(1994.2, w);
// console.log("priceHigh: ", Ph);

// console.log(left(x, price, price_high));
// console.log(right(y, price, price_low));
// console.log("w:", calculateW(price_low, price_high));
