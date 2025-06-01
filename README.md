# CMINUS 编译器

## 一、程序实现功能说明

本程序实现了 CMINUS 语言的词法分析与语法分析，能够检测如下类型的错误，并对部分重要特性进行了扩展和个性化处理。

### 1. 错误处理功能

#### 1.1 词法错误（错误类型A）
- 词法分析器（`src/lexer.l`）通过正则定义和默认规则自动识别非法字符，遇到不符合CMINUS词法的内容时会调用`lex_error`进行报错，精确到出错行。

#### 1.2 语法错误（错误类型B）
- 语法分析器（`src/parser.y`）采用Bison编写，通过规则和错误处理分支（如`Exp LB error RB`，调用`syn_error`）精确定位语法错误，并输出定制信息，便于调试和测试。

### 2. 关键特性实现

#### 2.1 八进制数与十六进制数识别
- 词法规则对八进制（`0[0-7]+`）和十六进制（`0[xX][0-9a-fA-F]+`）有专门正则，统一由`{INT}`规则识别。不合法数字（如`09`、`0x1G`）不会被匹配，直接报错。

#### 2.2 指数形式浮点数识别
- 浮点数规则`{FLOAT}`支持三种主流指数写法，非法指数形式（如`1.05e`）不会被匹配，直接报错。

#### 2.3 注释识别与错误处理
- 支持`//`单行注释和`/*...*/`多行注释，采用Flex状态机精确处理注释内容。多行注释未闭合时自动报错并准确定位起始行。

#### 2.4 其它支持
- 支持 CMINUS 关键字、操作符、标识符等，语法分析器构建语法树（AST），便于调试与后续拓展。

---

## 二、编译方法说明

本项目提供完整的自动化编译脚本，推荐使用`make`进行编译。

### 1. 依赖环境

- Ubuntu 或类 Unix 环境
- GCC（C99）
- Flex
- Bison
- Make

### 2. 编译步骤

#### 方式一：本地编译
1. 安装依赖（如未安装）：
   ```sh
   sudo apt-get install gcc make flex bison
   ```
2. 在项目根目录下执行：
   ```sh
   make
   ```
   编译成功后生成目标文件 `build/cc`。

3. 运行测试用例：
   ```sh
   make test
   ```
   或直接用：
   ```
   ./build/cc sample_ok.cminus
   ./build/cc sample_lexerr.cminus
   ./build/cc sample_synerr.cminus
   ```

#### 方式二：使用 Docker 编译
- 项目自带 `Dockerfile`，可用如下命令一键编译并进入容器环境：
  ```sh
  docker build -t cminus .
  docker run -it --rm cminus
  ```
- 容器内已自动执行`make`，也可手动运行测试。

#### 方式三：CI 自动化
- 项目集成 GitHub Actions，自动在主分支执行编译和测试，保证主分支代码持续可用。

---

## 三、程序亮点与独创性内容

本项目在以下方面体现了较强的独创性和工程化水平：

### 1. 错误处理机制的精细化与工程化

- **独立错误接口设计**  
  通过`lex_error`和`syn_error`接口，将词法和语法错误处理解耦，各自独立输出、精确到行，并支持格式化定制错误信息。接口声明如下：
  ```c
  // include/error.h
  void lex_error(int line, const char *fmt, ...);
  void syn_error(int line, const char *fmt, ...);
  ```
- **定制化语法错误分支**  
  在`parser.y`中，常见易错点（如括号、数组下标等）专门用`error`分支配合`syn_error`输出针对性、友好的报错提示。例如：
  ```yacc
  Exp LB error RB { 
      extern int yylineno; 
      syn_error(yylineno, "Missing \"]\""); 
  }
  ```
  并通过重载Bison默认`yyerror`接口，避免冗余信息，所有语法错误均自定义输出。
- **词法错误精确定位**
  词法无法识别字符时用如下方式报错，直观明了：
  ```lex
  . {
      lex_error(yylineno, "Unknown character: '%s'", yytext);
  }
  ```

### 2. 词法规则的高效表达与边界检测

- **多进制/浮点数正则表达式设计**
  八进制、十六进制、十进制、三类指数浮点数分别有简洁而严密的正则规则，自动区分各种合法数字并过滤错误格式。例如：
  ```lex
  INT10      0|([1-9][0-9]*)
  INT8       0[0-7]+
  INT16      0[xX][0-9a-fA-F]+
  INT        ({INT16}|{INT8}|{INT10})

  FLOATA     {DIGIT}+\.{DIGIT}*([eE][+-]?{DIGIT}+)?  // 常规浮点
  FLOATB     \.{DIGIT}+([eE][+-]?{DIGIT}+)?          // 点前无整数
  FLOATC     {DIGIT}+[eE][+-]?{DIGIT}+               // 整数指数
  FLOAT      ({FLOATA}|{FLOATB}|{FLOATC})
  ```

### 3. 注释处理的健壮性和边界检测

- **多行注释状态机与未闭合检测**  
  采用Flex的`%x COMMENT`机制，将多行注释处理拆解为状态迁移，支持跨行内容，并在文件结束时检测未闭合注释，输出精准错误提示。例如：
  ```lex
  <COMMENT><<EOF>> {
      fprintf(stderr, "Error: Unterminated comment started at line %d\n", comment_line_start);
      exit(1);
  }
  ```

### 4. 抽象语法树(AST)的模块化设计

- **AST节点生成的通用性**  
  通过`new_token`和`new_nonterm`两个接口，结合变参函数实现灵活的语法树节点生成，便于语法规则扩展和后续语义分析/中间代码生成。

### 5. 工程自动化与可移植性

- **Makefile与Dockerfile结合**  
  项目不仅有标准Makefile支持一键编译、测试和清理，还配有Dockerfile，保证任何环境下都能快速复现结果，提升可移植性与一致性。
- **CI流程保障主分支质量**  
  集成GitHub Actions，主分支和PR流程自动编译测试，保障项目质量。

---

## 四、错误输出样例

假设源码为：
```c
int a = 09;      // 不合法八进制数
if (a[1 2]) {    // 缺少逗号或右中括号
/* 注释未闭合
```
运行后输出：
```
Error at line 1: Unknown character: '09'
Error at line 2: Missing "]"
Error: Unterminated comment started at line 3
```
每条错误都包含准确行号和详细提示，便于快速定位和修正问题。

---

## 五、结论

本项目不仅实现了 CMINUS 语言的标准词法、语法分析与错误处理，还在错误输出精细化、词法边界检测、注释健壮性、AST设计和工程自动化等方面有诸多独创性和亮点。推荐测试时重点关注各种边界条件和错误场景，体验程序的健壮性和易用性。
