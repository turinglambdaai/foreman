# Foreman

**Racket 上的产生式规则系统——左边声明模式，右边就是 Racket 过程。**

[![CI](https://github.com/turinglambdaai/foreman/actions/workflows/ci.yml/badge.svg)](https://github.com/turinglambdaai/foreman/actions/workflows/ci.yml) ![Racket](https://img.shields.io/badge/Racket-9F1D20?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

**[English](README.md) · 中文**

Foreman 运行规则程序：事实进入工作记忆，规则声明自己关心的事实形状以及如何处置，引擎循环——全部匹配、点火一条、再来一轮——直到无事可做。左边保持声明式；右边是有完整语言加持的普通 Racket 过程。

Foreman 不是前向规划器，也不是带推理 DSL 的专家系统壳。它就是一个小而确定的引擎，外加三条明写的冲突消解准则（新近度、特异性、声明顺序），没有隐藏语义。

## 快速开始

```racket
(require foreman)

(define engine
  (make-engine
   #:rules
   (list
    (rule 'count-up
          (list '(counter value (? v)))
          (lambda (m)
            (define v (hash-ref (match-record-vars m) 'v))
            (define counter (car (match-record-elements m)))
            (if (< v 5)
                (list (modify-action counter (list 'value (+ v 1))))
                (list (remove-action counter))))))))

(engine-assert! engine 'counter 'value 0)
(engine-run! engine)   ; 点火六次：五次递增，最后一次移除
```

`examples/warehouse.rkt` 是一个可运行的完整走查——一个机器人、两个包裹、三条规则——CI 里离线执行。

## 设计要点

- **该声明的地方声明。** 模式就是普通数据：常量、通配符 `_`、`(? 变量)`。同名变量跨模式做连接；没有别的语法要学。
- **该过程的地方过程。** 右侧是返回动作的 Racket 过程（`make-action`、`remove-action`、`modify-action`）。聚合条件、算术、日志、I/O——都是 Racket 本身。
- **构造上确定。** 最新事实优先，其次最具体模式，再次声明顺序；平局保持枚举顺序。同一程序、同一断言顺序，结果必同。
- **停摆有界。** 不改变任何事实的右侧下一轮还会匹配；`#:max-cycles` 把任何此类停摆变成有界、可观察的一次运行。

## 开发

```sh
raco pkg install --auto --name foreman .
raco test -p foreman
raco setup --check-pkg-deps foreman
racket examples/warehouse.rkt
```

CI 在 Linux、Windows、macOS 三平台 × Racket 9.0 / 9.3 上跑测试，并做依赖声明检查、参考手册构建与走查。

## 许可证

[Apache-2.0](LICENSE)
