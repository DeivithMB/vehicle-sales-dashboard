-- Vehicle Sales Dashboard (v1) · PostgreSQL views
-- Source: schema "sales" (tables funnel, customers, products, stores)
-- Each view feeds one visual in projeto1_dashboard.pbix (Power BI, Import mode).
-- Scripts exported from the database with pg_views.

-- ======================================================================
-- vw_monthly_kpis: Monthly KPIs: leads (visit month), sales and revenue (payment month), conversion and average ticket
-- ======================================================================
create or replace view sales.vw_monthly_kpis as
 WITH leads AS (
         SELECT (date_trunc('month'::text, (funnel.visit_page_date)::timestamp with time zone))::date AS visit_page_month,
            count(*) AS visit_page_count
           FROM sales.funnel
          GROUP BY ((date_trunc('month'::text, (funnel.visit_page_date)::timestamp with time zone))::date)
          ORDER BY ((date_trunc('month'::text, (funnel.visit_page_date)::timestamp with time zone))::date)
        ), payments AS (
         SELECT (date_trunc('month'::text, (fun.paid_date)::timestamp with time zone))::date AS paid_month,
            count(fun.paid_date) AS paid_count,
            sum((pro.price * ((1)::numeric + fun.discount))) AS receita
           FROM (sales.funnel fun
             LEFT JOIN sales.products pro ON (((fun.product_id)::text = (pro.product_id)::text)))
          WHERE (fun.paid_date IS NOT NULL)
          GROUP BY ((date_trunc('month'::text, (fun.paid_date)::timestamp with time zone))::date)
          ORDER BY ((date_trunc('month'::text, (fun.paid_date)::timestamp with time zone))::date)
        )
 SELECT leads.visit_page_month AS "mês",
    leads.visit_page_count AS "leads (#)",
    payments.paid_count AS "vendas (#)",
    (payments.receita / (1000)::numeric) AS "receita (k, R$)",
    ((payments.paid_count)::double precision / (leads.visit_page_count)::double precision) AS "conversão (%)",
    ((payments.receita / (payments.paid_count)::numeric) / (1000)::numeric) AS "ticket médio (k, R$)"
   FROM (leads
     LEFT JOIN payments ON ((leads.visit_page_month = payments.paid_month)));

-- ======================================================================
-- vw_sales_by_brand: Sales by brand and month
-- ======================================================================
create or replace view sales.vw_sales_by_brand as
 SELECT pro.brand AS marca,
    count(fun.paid_date) AS "vendas (#)",
    (date_trunc('month'::text, (fun.paid_date)::timestamp with time zone))::date AS "mês"
   FROM (sales.funnel fun
     LEFT JOIN sales.products pro ON (((fun.product_id)::text = (pro.product_id)::text)))
  WHERE (fun.paid_date IS NOT NULL)
  GROUP BY pro.brand, ((date_trunc('month'::text, (fun.paid_date)::timestamp with time zone))::date)
  ORDER BY (count(fun.paid_date)) DESC;

-- ======================================================================
-- vw_sales_by_state: Sales by state and month (used by the map)
-- ======================================================================
create or replace view sales.vw_sales_by_state as
 SELECT 'BR'::text AS "país",
    cus.state AS estado,
    count(fun.paid_date) AS "vendas (#)",
    (date_trunc('month'::text, (fun.paid_date)::timestamp with time zone))::date AS "mês"
   FROM (sales.customers cus
     LEFT JOIN sales.funnel fun ON (((cus.customer_id)::text = (fun.customer_id)::text)))
  WHERE (fun.paid_date IS NOT NULL)
  GROUP BY 'BR'::text, cus.state, ((date_trunc('month'::text, (fun.paid_date)::timestamp with time zone))::date)
  ORDER BY (count(fun.paid_date)) DESC;

-- ======================================================================
-- vw_sales_by_store: Sales by store and month
-- ======================================================================
create or replace view sales.vw_sales_by_store as
 SELECT sto.store_id,
    sto.store_name AS loja,
    count(fun.paid_date) AS "vendas (#)",
    (date_trunc('month'::text, (fun.paid_date)::timestamp with time zone))::date AS "mês"
   FROM (sales.funnel fun
     LEFT JOIN sales.stores sto ON (((fun.store_id)::text = (sto.store_id)::text)))
  WHERE (fun.paid_date IS NOT NULL)
  GROUP BY sto.store_name, sto.store_id, ((date_trunc('month'::text, (fun.paid_date)::timestamp with time zone))::date)
  ORDER BY (count(fun.paid_date)) DESC;

-- ======================================================================
-- vw_visits_by_weekday: Site visits by weekday and month
-- ======================================================================
create or replace view sales.vw_visits_by_weekday as
 SELECT EXTRACT(dow FROM visit_page_date) AS dia_semana,
        CASE
            WHEN (EXTRACT(dow FROM visit_page_date) = (0)::numeric) THEN 'Domingo'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (1)::numeric) THEN 'Segunda-Feira'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (2)::numeric) THEN 'Terça-Feira'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (3)::numeric) THEN 'Quarta-Feira'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (4)::numeric) THEN 'Quinta-Feira'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (5)::numeric) THEN 'Sexta-Feira'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (6)::numeric) THEN 'Sábado'::text
            ELSE NULL::text
        END AS "dia da semana",
    count(*) AS "visitas (#)",
    (date_trunc('month'::text, (visit_page_date)::timestamp with time zone))::date AS "mês"
   FROM sales.funnel
  GROUP BY (EXTRACT(dow FROM visit_page_date)),
        CASE
            WHEN (EXTRACT(dow FROM visit_page_date) = (0)::numeric) THEN 'Domingo'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (1)::numeric) THEN 'Segunda-Feira'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (2)::numeric) THEN 'Terça-Feira'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (3)::numeric) THEN 'Quarta-Feira'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (4)::numeric) THEN 'Quinta-Feira'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (5)::numeric) THEN 'Sexta-Feira'::text
            WHEN (EXTRACT(dow FROM visit_page_date) = (6)::numeric) THEN 'Sábado'::text
            ELSE NULL::text
        END, ((date_trunc('month'::text, (visit_page_date)::timestamp with time zone))::date)
  ORDER BY ((date_trunc('month'::text, (visit_page_date)::timestamp with time zone))::date), (EXTRACT(dow FROM visit_page_date));
