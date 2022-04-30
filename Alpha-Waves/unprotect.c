#include <unistd.h>
#include <stdio.h>

int main()
{
    int row = 0, col = 0;
    unsigned char code0, code1;

    printf("    A    B    C    D    E    F    G    H    I    J\n");
    for (col = '1'; col <= '8'; col++)
    {
        printf ("%c", col);

        for (row = 'A'; row <= 'J'; row++)
        {
            read(0, &code0, 1);
            read(0, &code1, 1);
            printf(" %04d", code0*256 + code1);
        }
        printf("\n");
    }
}
