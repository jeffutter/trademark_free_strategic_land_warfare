defmodule TrademarkFreeStrategicLandWarfare.BoardTest do
  use ExUnit.Case

  alias TrademarkFreeStrategicLandWarfare.Board

  def shuffled_pieces() do
    Board.piece_name_counts()
    |> Enum.flat_map(fn {type, count} ->
      for _ <- 1..count, do: type
    end)
    |> Enum.shuffle()
  end

  def good_piece_setup() do
    Enum.chunk_every(shuffled_pieces(), 10)
  end

  def bad_piece_setup() do
    [replace_this, with_this] =
      Board.piece_name_counts()
      |> Map.keys()
      |> Enum.shuffle()
      |> Enum.take(2)

    shuffled_pieces()
    |> Enum.map(fn piece ->
      case piece do
        ^replace_this -> with_this
        piece -> piece
      end
    end)
    |> Enum.chunk_every(4)
  end

  def placements_from_board(board, player) do
    board.rows
    |> Board.maybe_flip(player)
    |> Enum.drop(6)
    |> Enum.map(fn row ->
      Enum.map(row, fn column -> column.name end)
    end)
  end

  describe "piece_name_counts" do
    test "returns a hash with correct piece counts" do
      counts = Board.piece_name_counts()
      assert counts[:marshall] == 1
      assert counts[:miner] == 5
    end
  end

  describe "init_pieces" do
    test "for player 1, no flip necessary" do
      placements = good_piece_setup()
      {:ok, new_board} = Board.init_pieces(Board.new(), placements, 1)
      assert placements_from_board(new_board, 1) == placements
    end

    test "for player 2, flip the board to player perspective before inserting" do
      placements = good_piece_setup()
      {:ok, new_board} = Board.init_pieces(Board.new(), placements, 2)
      assert placements_from_board(new_board, 2) == placements
    end

    test "doesn't mess up previously placed pieces" do
      [player_1_placements, player_2_placements] = for _ <- 1..2, do: good_piece_setup()

      {:ok, board_with_player_1_placements} =
        Board.init_pieces(Board.new(), player_1_placements, 1)

      {:ok, board_with_player_2_placements} =
        Board.init_pieces(board_with_player_1_placements, player_2_placements, 2)

      assert placements_from_board(board_with_player_1_placements, 1) == player_1_placements
      assert placements_from_board(board_with_player_2_placements, 2) == player_2_placements
    end

    test "returns a board with 10 rows" do
      placements = good_piece_setup()
      {:ok, new_board} = Board.init_pieces(Board.new(), placements, 2)
      assert length(new_board.rows) == 10
    end

    test "has lake pieces in the correct places" do
      placements = good_piece_setup()
      {:ok, new_board} = Board.init_pieces(Board.new(), placements, 2)
      rows = new_board.rows

      for {x, y} <- [{2, 4}, {3, 4}, {6, 4}, {7, 4}, {2, 5}, {3, 5}, {6, 5}, {7, 5}] do
        assert get_in(rows, [Access.at(y), Access.at(x)]) == :lake
      end
    end

    test "can't pass incorrect piece counts" do
      placements = bad_piece_setup()
      assert {:error, _} = Board.init_pieces(Board.new(), placements, 2)
    end

    test "can't pass something other than 4 rows of 10" do
      placements =
        good_piece_setup()
        |> List.flatten()
        |> Enum.chunk_every(11)

      assert {:error, _} = Board.init_pieces(Board.new(), placements, 2)
    end

    # mask board
    #   player 1
    #   player 2
    # move
    #   all 4 directions
    #   not into a lake
    #   not outside boundary
    #   attacks
  end

  # describe "new" do

  #  test "fails when no name is passed" do
  #    assert_raise RuntimeError, ~r/^player must have a name!$/, fn ->
  #      Player.new(nil, 1)
  #    end
  #  end

  #  test "creates a new player will work for player 1 or 2" do
  #    name = ThisPlayer

  #    for n <- 1..2 do
  #      assert %Player{player: ^n, name: ^name} = Player.new(name, n)
  #    end
  #  end

  #  test "create a new player won't work for players outside that range" do
  #    assert_raise RuntimeError, ~r/^player valid range is 1-2!$/, fn ->
  #      Player.new(WhichPlayer, 3)
  #    end
  #  end
  # end
end
