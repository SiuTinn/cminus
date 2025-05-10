.DEFAULT_GOAL := all
# ---------- 路径 ----------
BUILD   := build
INCLUDE := include
SRC     := src

LEXER   := $(SRC)/lexer.l
PARSER  := $(SRC)/parser.y
OBJS    := $(BUILD)/ast.o $(BUILD)/symbol_table.o \
           $(BUILD)/semantic.o $(BUILD)/utils.o \
           $(BUILD)/error.o $(BUILD)/main.o
TARGET  := $(BUILD)/cc

# ---------- 自动生成 ----------
$(BUILD)/parser.tab.c $(BUILD)/parser.tab.h: $(PARSER) | $(BUILD)
		bison -v -t -o $(BUILD)/parser.tab.c -d $<

$(BUILD)/lex.yy.c: $(LEXER) $(BUILD)/parser.tab.h | $(BUILD)
		flex -o $@ $<

# ---------- 编译 ----------
$(BUILD)/%.o: $(SRC)/%.c | $(BUILD)
		gcc -std=c99 -I$(INCLUDE) -c $< -o $@

$(TARGET): $(BUILD)/lex.yy.c $(BUILD)/parser.tab.c $(OBJS)
		gcc -std=c99 -I$(INCLUDE) $^ -o $@

# ---------- 伺服 ----------
.PHONY: all test clean
all: $(TARGET)

test: all
		@for f in tests/*.cminus; do \
			echo "==> $$f"; ./$(TARGET) $$f; echo; \
		done

clean:
		rm -rf $(BUILD)

$(BUILD):
		mkdir -p $(BUILD)
