static int global = 0xAABBCCDD;

int main(void)
{
	int i = 5;
	int n = 7;
	int k = 9;
	int j = 1944;
	static int s = 2;

	k += n;
	n += i;
	i += n+k;
	k -= global;
	j /= s;
}
