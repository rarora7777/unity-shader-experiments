float cmag2(float2 a)
{
	return a[0] * a[0] + a[1] * a[1];
}

float cmag(float2 a)
{
	return sqrt(cmag2(a));
}

float carg(float2 a)
{
	return atan2(a[1], a[0]);
}

float2 cconj(float2 a)
{
	return float2(a[0], -a[1]);
}

float2 cmul(float2 a, float2 b)
{
	float2 res;
	float a0b0 = a[0] * b[0];
	float a1b1 = a[1] * b[1];
	res[0] = a0b0 - a1b1;
	res[1] = (a[0] + a[1]) * (b[0] + b[1]) - a0b0 - a1b1;
	return res;
}

float2 cdiv(float2 a, float2 b)
{
	float2 res;
	res[0] = a[0] * b[0] + a[1] * b[1];
	res[1] = a[1] * b[0] - a[0] * b[1];
	float b2 = cmag2(b);
	return res / b2;
}

float clogre(float2 a)
{
	return log(cmag(a));
}

float clogim(float2 a)
{
	return atan2(a[1], a[0]);
}

float2 clog(float2 a)
{
	return float2(clogre(a), clogim(a));
}

float2 cpow(float2 a, int n)
{
	float2 res = float2(1, 0);
	uint n0;

	if (n == 0)
		return float2(1, 0);
	else if (n < 0)
	{
		if (cmag2(a) < 1e-6)
			return float2(0, 0);
		a = cdiv(res, a);
		n = -n;
	}

	n0 = n;

	while (n0 > 1)
	{
		if (n0 % 2 == 0)
		{
			a = cmul(a, a);
			n0 = n0 / 2;
		}
		else
		{
			res = cmul(a, res);
			a = cmul(a, a);
			n0 = (n0 - 1) / 2;
		}
	}
	return cmul(a, res);
}

float2 cpolyeval(float2 z, float2 coeff[10], int k)
{
	float2 res = float2(0.0f, 0.0f);
	for (int i = 0; i < k; ++i)
	{
		res += cmul(coeff[i], cpow(z, i));
	}

	return res;
}

float2 StereographicStoP(float3 p)
{
	// p = (X, Y, Z)
	// z = x + iy = (X + iY) / (1-Z)
	return cdiv(p.xy, 1.0f - p.z);
}

float3 StereographicPtoS(float2 z)
{
	float3 p;
	// p = (X, Y, Z)
	// X + iY = 2z / (1 + |z|²)
	// Z = (|z|² - 1) / (|z|² + 1)
	float mag2 = cmag2(z);
	float2 XY = 2.0f * z / (1.0f + mag2);
	float Z = (mag2 - 1.0f) / (mag2 + 1.0f);
	return float3(XY, Z);
}