defmodule MakeupKanren do
  @moduledoc """
  miniKanren (Scheme style) lexer for the Makeup syntax highlighter.

  Using *The Reasoned Schemer*'s format.
  """
  import NimbleParsec
  import Makeup.Lexer.Combinators

  @behaviour Makeup.Lexer

  ###################################################################
  # 1. Basic Characters Defination
  ###################################################################

  allowed_in_ident =
    utf8_char([
      {:not, ?\s}, {:not, ?\t}, {:not, ?\n}, {:not, ?\r},
      {:not, ?(}, {:not, ?)}, {:not, ?[}, {:not, ?]},
      {:not, ?"}, {:not, ?;}, {:not, ?'}
    ])

  ###################################################################
  # 2. Combinators
  ###################################################################

  whitespace = ascii_string([?\s, ?\t, ?\n, ?\r], min: 1) |> token(:whitespace)

  comment =
    string(";")
    |> repeat(utf8_char([{:not, ?\n}]))
    |> token(:comment_single)

  digits = ascii_string([?0..?9], min: 1)
  number =
    optional(string("-"))
    |> concat(digits)
    |> token(:number_integer)

  string_literal = string_like("\"", "\"", [string("\\\"")], :string)

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

  identifier =
    times(allowed_in_ident, min: 1)
    |> token(:name)

  ###################################################################
  # 3. Root Parser
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

  ###################################################################
  # 4. API Implementation
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

  def post_process_token(token, _opts \\ []) do
    case token do
      {:name, attrs, text} ->
        process_identifier(text, attrs)

      other ->
        other
    end
  end

  ###################################################################
  # 5. Token Classification
  ###################################################################

  defp process_identifier(text, attrs) do
    case text do
      # --- miniKanren core Keyword ---
      ~c"run" -> {:keyword_declaration, attrs, text}
      ~c"run*" -> {:keyword_declaration, attrs, text}
      ~c"fresh" -> {:keyword, attrs, text}
      ~c"conde" -> {:keyword, attrs, text}
      ~c"condᵉ" -> {:keyword, attrs, text}
      ~c"conda" -> {:keyword, attrs, text} # Soft cut (扩展)
      ~c"condᵃ" -> {:keyword, attrs, text}
      ~c"condu" -> {:keyword, attrs, text} # Committed choice (扩展)
      ~c"condᵘ" -> {:keyword, attrs, text}
      ~c"defrel" -> {:keyword_declaration, attrs, text} # 定义关系
      ~c"project" -> {:keyword, attrs, text}

      # --- Operator ---
      ~c"==" -> {:operator, attrs, text} # Unification
      ~c"≡" -> {:operator, attrs, text}
      ~c"=/=" -> {:operator, attrs, text} # Disequality constraint
      ~c"≠" -> {:operator, attrs, text}
      ~c"≢" -> {:operator, attrs, text}

      # --- Scheme Kyword (Context) ---
      ~c"define" -> {:keyword_declaration, attrs, text}
      ~c"lambda" -> {:keyword_declaration, attrs, text}
      ~c"λ" -> {:keyword_declaration, attrs, text}
      ~c"let" -> {:keyword, attrs, text}
      ~c"cons" -> {:name_builtin, attrs, text}
      ~c"car" -> {:name_builtin, attrs, text}
      ~c"cdr" -> {:name_builtin, attrs, text}
      ~c"null?" -> {:name_builtin, attrs, text}
      ~c"pair?" -> {:name_builtin, attrs, text}
      ~c"else" -> {:keyword, attrs, text}

      # --- Constants ---
      ~c"#t" -> {:string_symbol, attrs, text}
      ~c"#f" -> {:string_symbol, attrs, text}
      ~c"#u" -> {:string_symbol, attrs, text} # fail in some impls
      ~c"#s" -> {:string_symbol, attrs, text} # succeed in some impls

      _ -> {:name, attrs, text}
    end
  end
end
