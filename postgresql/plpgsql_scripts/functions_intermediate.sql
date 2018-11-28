-- DROP FUNCTION temporal_schema.udf_endangered_animals_reasons_tree_get(INTEGER);

CREATE OR REPLACE FUNCTION temporal_schema.udf_endangered_animals_reasons_tree_get()
 RETURNS json
 LANGUAGE plpgsql
AS $function$

DECLARE

  json_returning json = '{}';
    
  BEGIN        

  /*
  -- To Test:
    SELECT temporal_schema.udf_endangered_animals_reasons_tree_get();
  */

  WITH temporal_category_table AS (
      SELECT
        id_categories,
        name
      FROM
        temporal_schema.tb_categories
    ), temporal_relation_endangered_reasons AS (
        SELECT
          id_endangered_animals,
          id_categories,
          id_reasons
        FROM
          temporal_schema.tbl_relation_endangered_reasons
    )

    SELECT JSON_AGG(a.*) INTO STRICT json_returning
    FROM (
      SELECT
        tct.id_categories "categoryId",
        tct.name "categoryName",
        true as "is_active",
        (
          SELECT ARRAY_AGG(b.*) "animalList"
          FROM (
            SELECT
              -- DISTINCT ON (ea.id_endangered_animals) -- it also could be, distinct on rather than group by
              ea.id_endangered_animals "animalId",
              ea.name "animalName",
              true as "is_active",
              (
                SELECT JSON_AGG(c.*) "endangeredReasonsList"
                FROM (
                  SELECT 
                    r.id_reasons "reasonId",
                    r.description "reason",
                    true as "is_active"
                  FROM temporal_schema.tbl_reasons r
                    INNER JOIN temporal_relation_endangered_reasons trer
                      ON r.id_reasons =  trer.id_reasons
                      AND
                      trer.id_endangered_animals = ea.id_endangered_animals
                      AND
                      trer.id_categories = tct.id_categories
                )c
              )
            FROM temporal_schema.tbl_endangered_animals ea
              INNER JOIN temporal_schema.tbl_relation_endangered_reasons rer
                ON ea.id_endangered_animals = rer.id_endangered_animals
                AND
                ea.id_categories = rer.id_categories
                AND
                ea.id_categories = tct.id_categories
            GROUP BY
              ea.id_endangered_animals,
              ea.name
            ORDER BY 
              ea.id_endangered_animals
          )b
        )
      FROM 
        temporal_category_table tct
    )a;

    RETURN json_returning;

END;

$function$;

COMMENT ON FUNCTION temporal_schema.udf_endangered_animals_reasons_tree_get() IS 'This function is used to get a tree of endangered animals with endangered reasons.';
