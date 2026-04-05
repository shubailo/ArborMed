## 2024-04-05 - N+1 overhead in inline subqueries
**Learning:** Correlated inline subqueries in SELECT statements (like SELECT t.*, (SELECT COUNT(*) FROM...)) cause N+1 execution overhead in PostgreSQL.
**Action:** Use a CTE to pre-aggregate counts via GROUP BY and LEFT JOIN it back to the main table for O(1) query execution plan.
