defmodule MakeupKanren do
  @moduledoc """
  miniKanren (Scheme style) lexer for the Makeup syntax highlighter.

  Using *The Reasoned Schemer*'s format.
  """
  import NimbleParsec
  import Makeup.Lexer.Combinators
  # import Makeup.Lexer.Groups

  @behaviour Makeup.Lexer

  ###################################################################
  # 1. 基础字符定义
  ###################################################################

  # Scheme/Lisp 允许的标识符字符非常宽泛，但通常不包含括号、引号、分号和空白
  # 这里定义一个宽泛的非分隔符集合作为标识符的一部分
  # 注意：miniKanren 中的标识符可能包含 *, -, ?, ! 等符号
  allowed_in_ident =
    utf8_char([
      {:not, ?\s}, {:not, ?\t}, {:not, ?\n}, {:not, ?\r},
      {:not, ?(}, {:not, ?)}, {:not, ?[}, {:not, ?]},
      {:not, ?"}, {:not, ?;}, {:not, ?'} # 单引号通常用于 quote
    ])

  ###################################################################
  # 2. 组合子 (Combinators)
  ###################################################################

  whitespace = ascii_string([?\s, ?\t, ?\n, ?\r], min: 1) |> token(:whitespace)

  # 注释：以分号 ; 开头直到行尾
  comment =
    string(";")
    |> repeat(utf8_char([{:not, ?\n}]))
    |> token(:comment_single)

  # 数字：整数 (简化版，未处理浮点或分数，因为 miniKanren 主要处理逻辑)
  digits = ascii_string([?0..?9], min: 1)
  number =
    optional(string("-"))
    |> concat(digits)
    |> token(:number_integer)

  # 字符串：双引号包裹
  string_literal = string_like("\"", "\"", [string("\\\"")], :string)

  # 标点符号/分隔符
  punctuation =
    choice([
      string("("),
      string(")"),
      string("["),
      string("]"),
      string("'"), # Quote
      string("`"), # Quasiquote
      string(","), # Unquote
      string(".")  # Cons pair dot
    ])
    |> token(:punctuation)

  # 标识符 (Identifiers/Symbols)
  # 我们先匹配所有看起来像标识符的东西，然后在 post_process 中区分关键字
  identifier =
    times(allowed_in_ident, min: 1)
    |> token(:name)

  ###################################################################
  # 3. 根解析器
  ###################################################################

  root_element_combinator =
    choice([
      whitespace,
      comment,
      string_literal,
      punctuation,
      number,
      identifier
    ])
    # |> token(:root_element_combinator)

  ###################################################################
  # 4. API 实现
  ###################################################################
@impl Makeup.Lexer
  def lex(text, opts \\ []) do
    match_groups? = Keyword.get(opts, :match_groups, true)

    {:ok, tokens, "", _, _, _} = root(text)

    tokens = postprocess(tokens, opts)

    if match_groups? do
      match_groups(tokens, text)
    else
      tokens
    end
  end

  @impl Makeup.Lexer
  def postprocess(tokens, _opts \\ []) do
    Enum.map(tokens, &post_process_token/1)
  end

  @impl Makeup.Lexer
  def match_groups(tokens, _text \\ "") do
    tokens
  end

  @impl Makeup.Lexer
  defparsec(:root_element, root_element_combinator, inline: false)

  @impl Makeup.Lexer
  defparsec(:root, repeat(parsec(:root_element)), inline: false)

  # 这是一个很好的实践，用于处理特定的 token 映射
  # @impl Makeup.Lexer
  def post_process_token(token, _opts \\ []) do
    case token do
      {:name, attrs, text} ->
        process_identifier(text, attrs)

      other ->
        other
    end
  end

  ###################################################################
  # 5. 关键字映射 (Token Classification)
  ###################################################################

  defp process_identifier(text, attrs) do
    case text do
      # --- miniKanren core Keyword ---
      ~c"run" -> {:keyword_declaration, attrs, text}
      ~c"run*" -> {:keyword_declaration, attrs, text}
      ~c"fresh" -> {:keyword, attrs, text}
      ~c"conde" -> {:keyword, attrs, text}
      ~c"conda" -> {:keyword, attrs, text} # Soft cut (扩展)
      ~c"condu" -> {:keyword, attrs, text} # Committed choice (扩展)
      ~c"defrel" -> {:keyword_declaration, attrs, text} # 定义关系
      ~c"project" -> {:keyword, attrs, text}

      # --- Operator ---
      ~c"==" -> {:operator, attrs, text} # Unification
      ~c"=/=" -> {:operator, attrs, text} # Disequality constraint

      # --- Scheme Kyword (Context) ---
      ~c"define" -> {:keyword_declaration, attrs, text}
      ~c"lambda" -> {:keyword_declaration, attrs, text}
      ~c"let" -> {:keyword, attrs, text}
      ~c"cons" -> {:name_builtin, attrs, text}
      ~c"car" -> {:name_builtin, attrs, text}
      ~c"cdr" -> {:name_builtin, attrs, text}
      ~c"null?" -> {:name_builtin, attrs, text}
      ~c"pair?" -> {:name_builtin, attrs, text}
      ~c"else" -> {:keyword, attrs, text}

      # --- Constants ---
      ~c"#t" -> {:name_constant, attrs, text}
      ~c"#f" -> {:name_constant, attrs, text}
      ~c"#u" -> {:name_constant, attrs, text} # fail in some impls
      ~c"#s" -> {:name_constant, attrs, text} # succeed in some impls

      _ -> {:name, attrs, text}
    end
  end
end
