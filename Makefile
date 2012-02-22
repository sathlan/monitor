PREFIX ?= /usr/local
NAME=monitor

install: monitor.sh
	cp -fp monitor.sh $(PREFIX)/monitor
	chmod a+rx $(PREFIX)/monitor

uninstall:
	rm -f $(PREFIX)/bin/$(NAME)

# https://github.com/bmizerany/roundup
test:
	@which -s roundup || (echo "Missing roundup!"\
		" Cannot test." >&2 && exit 1)
	@which -s sar || (echo "Missing sar!"\
		" Cannot test." >&2 && exit 1)
	@roundup monitor-test.sh

.PHONY: install uninstall test
