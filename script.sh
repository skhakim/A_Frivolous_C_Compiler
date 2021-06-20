rm -f a.out
rm -f parser.tab.*
flex 1705002.l 
echo "Flexed! "
bison -d 1705002.y
echo "Bisoned! "
g++ -std=c++17 -w 1705002.tab.c -o bisonOffline
echo "Compiled! "
./bisonOffline input.txt
