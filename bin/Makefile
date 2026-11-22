CC = cc
CFLAGS = -Wall -Wextra -Wpedantic
LDLIBS =

# Targets
all: test_year test_a_year

test_year: test_leap_year.o is_leap_year.o
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS)

test_a_year: test_a_year.o is_leap_year.o
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS)

test_leap_year.o: test_leap_year.c
	$(CC) $(CFLAGS) -c $< -o $@

test_a_year.o: test_a_year.c
	$(CC) $(CFLAGS) -c $< -o $@

is_leap_year.o: is_leap_year.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f test_year test_a_year *.o
