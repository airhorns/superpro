# frozen_string_literal: true

class AddGapFillPostgresFunction < ActiveRecord::Migration[6.0]
  def up
    execute <<~SQL
              CREATE OR REPLACE FUNCTION GapFillInternal(
                  s anyelement,
                  v anyelement) RETURNS anyelement AS
              $$
              BEGIN
                RETURN COALESCE(v,s);
              END;
              $$ LANGUAGE PLPGSQL IMMUTABLE;



              CREATE AGGREGATE GapFill(anyelement) (
                SFUNC=GapFillInternal,
                STYPE=anyelement
              );
            SQL
  end

  def down
    execute <<~SQL
              DROP FUNCTION GapFillInternal;
              DROP AGGREGATE GapFill;
            SQL
  end
end
