"""
Finance / Banking Analytics — Full EDA Script
Project: Bank Loan Portfolio & Risk Analysis | 2023
Tools: pandas, numpy, matplotlib, seaborn
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

# ── Theme ──────────────────────────────────────────────────────
PALETTE = ['#1E2761','#3D5A99','#7B9ED9','#CADCFC','#F9E795','#F96167','#2F3C7E']
plt.rcParams.update({'font.family':'DejaVu Sans','axes.spines.top':False,
                     'axes.spines.right':False,'figure.facecolor':'white'})

df  = pd.read_csv('/home/claude/loan_transactions.csv')
bdf = pd.read_csv('/home/claude/branch_performance.csv')
df['Disbursement_Date'] = pd.to_datetime(df['Disbursement_Date'])
df['Month'] = df['Disbursement_Date'].dt.to_period('M').astype(str)

# ── Console Summary ────────────────────────────────────────────
print("="*60)
print("FINANCE / BANKING ANALYTICS  —  PYTHON EDA")
print("="*60)
print(f"\nDataset  : {df.shape[0]:,} loan records")
print(f"Date Range: {df['Disbursement_Date'].min().date()} → {df['Disbursement_Date'].max().date()}")
print(f"\nNull values: {df.isnull().sum().sum()}")
print(f"\nPortfolio Stats:")
print(df[['Loan_Amount','Interest_Rate_Pct','Credit_Score','Monthly_EMI']].describe().round(2).to_string())

# ── Figure 1: Main EDA Dashboard ──────────────────────────────
fig = plt.figure(figsize=(22,15))
fig.suptitle('Finance & Banking Analytics — Exploratory Data Analysis',
             fontsize=18, fontweight='bold', color='#1E2761', y=0.98)
gs = gridspec.GridSpec(3,3,figure=fig,hspace=0.45,wspace=0.35)

# 1) Monthly loan disbursement trend
ax1 = fig.add_subplot(gs[0,:2])
monthly = df.groupby('Month').agg(Count=('Loan_ID','count'),
                                   Volume=('Loan_Amount','sum')).reset_index()
ax1b = ax1.twinx()
ax1.bar(range(len(monthly)), monthly['Count'], color='#3D5A99', alpha=0.8, label='Loan Count')
ax1b.plot(range(len(monthly)), monthly['Volume']/1e9, color='#F96167',
          marker='o', linewidth=2.5, markersize=5, label='Volume ($B)')
ax1.set_xticks(range(len(monthly)))
ax1.set_xticklabels([m[-5:] for m in monthly['Month']], rotation=45, ha='right', fontsize=8)
ax1.set_title('Monthly Loan Disbursements', fontweight='bold', color='#1E2761')
ax1.set_ylabel('Loan Count', color='#3D5A99')
ax1b.set_ylabel('Volume ($B)', color='#F96167')
ax1.legend(loc='upper left'); ax1b.legend(loc='upper right')

# 2) Loan type mix — pie
ax2 = fig.add_subplot(gs[0,2])
lt = df['Loan_Type'].value_counts()
ax2.pie(lt, labels=None, autopct='%1.1f%%', colors=PALETTE[:len(lt)],
        startangle=90, pctdistance=0.8)
for t in ax2.texts: t.set_fontsize(7)
ax2.set_title('Loan Type Mix', fontweight='bold', color='#1E2761')
ax2.legend(lt.index, loc='lower center', bbox_to_anchor=(0.5,-0.28), ncol=2, fontsize=7)

# 3) NPA & default rate by risk grade
ax3 = fig.add_subplot(gs[1,0])
risk = df.groupby('Risk_Grade').agg(
    Default_Rate=('Is_Default','mean'), NPA_Rate=('Is_NPA','mean')).mul(100)
x = np.arange(len(risk))
ax3.bar(x-0.2, risk['Default_Rate'], 0.38, color='#F96167', label='Default Rate')
ax3.bar(x+0.2, risk['NPA_Rate'],     0.38, color='#1E2761', label='NPA Rate')
ax3.set_xticks(x); ax3.set_xticklabels(risk.index)
ax3.set_title('Default & NPA Rate by Risk Grade', fontweight='bold', color='#1E2761')
ax3.set_ylabel('Rate (%)'); ax3.legend(fontsize=8)
for i,v in enumerate(risk['Default_Rate']): ax3.text(i-0.2,v+0.2,f'{v:.1f}%',ha='center',fontsize=7)

# 4) Loan amount distribution
ax4 = fig.add_subplot(gs[1,1])
ax4.hist(np.log10(df['Loan_Amount']+1), bins=30, color='#3D5A99', edgecolor='white', alpha=0.85)
ax4.set_title('Loan Amount Distribution (log10)', fontweight='bold', color='#1E2761')
ax4.set_xlabel('log10(Loan Amount)')
ax4.set_ylabel('Count')
ax4.axvline(np.log10(df['Loan_Amount'].median()), color='#F96167',
            linestyle='--', linewidth=2, label=f"Median: ${df['Loan_Amount'].median():,.0f}")
ax4.legend(fontsize=8)

# 5) Credit score vs interest rate
ax5 = fig.add_subplot(gs[1,2])
colors_scatter = {'A':'#2C7BB6','B':'#ABD9E9','C':'#FFFFBF','D':'#FDAE61','E':'#D7191C'}
for g, grp in df.groupby('Risk_Grade'):
    ax5.scatter(grp['Credit_Score'], grp['Interest_Rate_Pct'],
                alpha=0.3, s=18, c=colors_scatter[g], label=g)
ax5.set_title('Credit Score vs Interest Rate', fontweight='bold', color='#1E2761')
ax5.set_xlabel('Credit Score'); ax5.set_ylabel('Interest Rate (%)')
ax5.legend(title='Risk Grade', fontsize=8, title_fontsize=8)

# 6) Portfolio by customer segment
ax6 = fig.add_subplot(gs[2,:2])
seg = df.groupby('Customer_Segment').agg(
    Count=('Loan_ID','count'), Volume=('Loan_Amount','sum'),
    Avg_Rate=('Interest_Rate_Pct','mean'), Default_Rate=('Is_Default','mean')
).reset_index()
colors_seg = ['#1E2761','#3D5A99','#7B9ED9','#CADCFC']
bars = ax6.bar(seg['Customer_Segment'], seg['Volume']/1e9, color=colors_seg)
ax6.set_title('Loan Portfolio Volume by Customer Segment ($B)', fontweight='bold', color='#1E2761')
ax6.set_ylabel('Volume ($B)')
for bar, v in zip(bars, seg['Volume']/1e9):
    ax6.text(bar.get_x()+bar.get_width()/2, v+0.05, f'${v:.1f}B', ha='center', fontsize=9, fontweight='bold')

# 7) Channel mix by segment — stacked bar
ax7 = fig.add_subplot(gs[2,2])
ch = df.groupby(['Channel','Customer_Segment']).size().unstack(fill_value=0)
ch.plot(kind='bar', ax=ax7, color=colors_seg, edgecolor='white', stacked=True)
ax7.set_title('Channel Mix by Segment', fontweight='bold', color='#1E2761')
ax7.set_ylabel('Count'); ax7.tick_params(axis='x', rotation=30)
ax7.legend(fontsize=7, title_fontsize=7)

plt.savefig('/home/claude/finance_eda_dashboard.png', dpi=150, bbox_inches='tight')
print("\nEDA dashboard saved.")

# ── Figure 2: Risk & NIM Analysis ─────────────────────────────
fig2, axes = plt.subplots(1,3,figsize=(18,5))
fig2.suptitle('Risk & Revenue Deep-Dive', fontsize=16, fontweight='bold', color='#1E2761')

# NIM by bank
nim = bdf.groupby('Bank')['Net_Interest_Margin_Pct'].mean().sort_values()
axes[0].barh(nim.index, nim.values, color='#3D5A99')
axes[0].set_title('Avg Net Interest Margin by Bank (%)', fontweight='bold')
axes[0].set_xlabel('NIM (%)')
for i,v in enumerate(nim.values): axes[0].text(v+0.03,i,f'{v:.2f}%',va='center',fontsize=9)

# NPA ratio heatmap (bank x region)
pivot = bdf.pivot_table(index='Bank', columns='Region', values='NPA_Ratio_Pct', aggfunc='mean')
sns.heatmap(pivot, annot=True, fmt='.1f', cmap='RdYlGn_r', ax=axes[1],
            linewidths=0.5, cbar_kws={'label':'NPA %'})
axes[1].set_title('NPA Ratio % (Bank × Region)', fontweight='bold')
axes[1].tick_params(axis='x', rotation=30)

# CASA ratio vs Attrition
axes[2].scatter(bdf['CASA_Ratio_Pct'], bdf['Attrition_Rate_Pct'],
                s=bdf['Total_Deposits']/1e7, c='#1E2761', alpha=0.7)
corr = bdf[['CASA_Ratio_Pct','Attrition_Rate_Pct']].corr().iloc[0,1]
axes[2].set_title(f'CASA Ratio vs Customer Attrition (r={corr:.2f})', fontweight='bold')
axes[2].set_xlabel('CASA Ratio (%)'); axes[2].set_ylabel('Attrition Rate (%)')
z = np.polyfit(bdf['CASA_Ratio_Pct'], bdf['Attrition_Rate_Pct'], 1)
xl = np.linspace(bdf['CASA_Ratio_Pct'].min(), bdf['CASA_Ratio_Pct'].max(), 50)
axes[2].plot(xl, np.poly1d(z)(xl), 'r--', linewidth=2)
for ax in axes: ax.spines['top'].set_visible(False); ax.spines['right'].set_visible(False)

plt.tight_layout()
plt.savefig('/home/claude/finance_risk_analysis.png', dpi=150, bbox_inches='tight')
print("Risk analysis chart saved.")

# ── Key findings ───────────────────────────────────────────────
print("\n── KEY FINDINGS ──────────────────────────────────────────")
def_by_grade = df.groupby('Risk_Grade')['Is_Default'].mean()*100
npa_by_seg   = df.groupby('Customer_Segment')['Is_NPA'].mean()*100
rev_by_type  = df.groupby('Loan_Type')['Net_Interest_Income'].sum()/1e9

print(f"  Grade-E default rate     : {def_by_grade['E']:.1f}% vs Grade-A {def_by_grade['A']:.1f}%")
print(f"  Highest NPA segment      : {npa_by_seg.idxmax()} ({npa_by_seg.max():.1f}%)")
print(f"  Top revenue loan type    : {rev_by_type.idxmax()} (${rev_by_type.max():.2f}B NII)")
print(f"  Avg NIM across branches  : {bdf['Net_Interest_Margin_Pct'].mean():.2f}%")
print(f"  Worst NPA bank-region    : {bdf.loc[bdf['NPA_Ratio_Pct'].idxmax(),['Bank','Region']].values}")
corr_cs_rate = df[['Credit_Score','Interest_Rate_Pct']].corr().iloc[0,1]
print(f"  Corr(Credit Score, Rate) : {corr_cs_rate:.2f}")
